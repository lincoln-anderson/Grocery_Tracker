//
//  AddItemView.swift
//  Grocery_Tracker
//
//  Created by lincoln anderson on 4/28/21.
//

import CoreData
import SwiftUI
import UserNotifications

struct AddItemView: View {

  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .body) private var pickerHeight: CGFloat = 120

  @Binding var isPresented: Bool

  @State var newName: String = ""

  @State var expirationDate: Date

  @State var purchaseDate: Date

  @State var quantity: Int = 1

  @State var measurement: String = Measurements.oz.rawValue

  @State var sendNotification: Bool = true

  @State var notificationTime: Int = 3
  @State private var persistenceError: (any Error)?
  @State private var notificationError: (any Error)?
  @State private var isSaving = false

  private enum ReminderError: Error {
    case authorizationDenied
  }

  enum Measurements: String, CaseIterable, Identifiable {

    case oz
    case lb
    case ml

    var id: String { self.rawValue }

  }

  var body: some View {
    let horizontalOrVerticalLayout =
      dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
      : AnyLayout(HStackLayout(spacing: 16))

    GeometryReader { geometry in
      ScrollView {
        VStack {
          Spacer(minLength: 0)
          VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
              Text("New Grocery Item")
                .font(.title2)
                .bold()
                .foregroundColor(.sproutGreen)
                .padding(.top)
                .padding(.horizontal)

              Divider()
                .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 6) {
              Text("Item Name")
                .font(.subheadline)
                .foregroundColor(.sproutGreen)

              TextField("Item Name", text: $newName)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            horizontalOrVerticalLayout {
              VStack(alignment: .leading, spacing: 6) {
                Text("Purchase Date")
                  .font(.subheadline)
                  .foregroundColor(.sproutGreen)

                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                  .datePickerStyle(.compact)
                  .labelsHidden()
                  .padding(12)
                  .background(Color(.systemGray6))
                  .cornerRadius(10)
              }
              .frame(maxWidth: .infinity, alignment: .leading)

              VStack(alignment: .leading, spacing: 6) {
                Text("Expiration Date")
                  .font(.subheadline)
                  .foregroundColor(.sproutGreen)

                DatePicker("", selection: $expirationDate, displayedComponents: .date)
                  .datePickerStyle(.compact)
                  .labelsHidden()
                  .padding(12)
                  .background(Color(.systemGray6))
                  .cornerRadius(10)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            VStack(alignment: .leading, spacing: 6) {
              Text("Quantity & Measurement")
                .font(.subheadline)
                .foregroundColor(.sproutGreen)

              horizontalOrVerticalLayout {
                Picker("Quantity", selection: $quantity) {
                  ForEach(1...100, id: \.self) {
                    Text("\($0)")
                  }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .pickerStyle(.wheel)

                Picker("Measurement", selection: $measurement) {
                  ForEach(Measurements.allCases) { measurement in
                    Text(measurement.rawValue.capitalized)
                  }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .pickerStyle(.wheel)
              }
              .frame(
                minHeight: dynamicTypeSize.isAccessibilitySize
                  ? pickerHeight * 2
                  : pickerHeight
              )
              .padding(12)
              .background(Color(.systemGray6))
              .cornerRadius(10)
            }
            .padding(.horizontal)
            VStack(alignment: .leading, spacing: 12) {
              Text("Expiration Alert")
                .font(.headline)
                .padding(.bottom, 2)

              Toggle("Enable Notification", isOn: $sendNotification)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.32, green: 0.55, blue: 0.39)))

              Text("Remind me this many days before expiration:")
                .font(.subheadline)
                .foregroundColor(.sproutGreen)

              Picker("", selection: $notificationTime) {
                ForEach(1...5, id: \.self) { day in
                  Text("\(day)")
                }
              }
              .pickerStyle(.segmented)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            Button {
              Task {
                await saveItem()
              }
            } label: {
              Text("Save Item")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.sproutGreen)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                .padding(.horizontal)
            }
            .disabled(isSaving)
          }

          Spacer(minLength: 0)
        }
        .frame(minHeight: geometry.size.height)
        .padding(.vertical)
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .alert("Couldn’t Save Item", item: $persistenceError) { _ in
      Button("OK", role: .cancel) {}
    } message: { _ in
      Text("Your item couldn’t be saved. Please try again.")
    }
    .alert("Reminder Not Scheduled", item: $notificationError) { _ in
      Button("OK", role: .cancel) {
        isPresented = false
      }
    } message: { _ in
      Text("The item was saved, but its expiration reminder couldn’t be scheduled.")
    }
  }

  private func saveItem() async {
    guard !isSaving else { return }

    isSaving = true
    defer { isSaving = false }

    do {
      try newItem(
        newName: newName,
        expirationDate: expirationDate,
        purchaseDate: purchaseDate,
        quantity: Int16(quantity),
        measurement: measurement
      )
    } catch {
      persistenceError = error
      return
    }

    guard sendNotification else {
      isPresented = false
      return
    }

    do {
      try await scheduleExpirationReminder()
      isPresented = false
    } catch {
      notificationError = error
    }
  }

  private func scheduleExpirationReminder() async throws {
    let notificationCenter = UNUserNotificationCenter.current()
    let isAuthorized = try await notificationCenter.requestAuthorization(
      options: [.alert, .sound]
    )

    guard isAuthorized else {
      throw ReminderError.authorizationDenied
    }

    let calendar = Calendar.current
    let reminderDate = try ExpirationReminderCalculator.reminderDate(
      for: expirationDate,
      daysBefore: notificationTime,
      calendar: calendar
    )

    let content = UNMutableNotificationContent()
    content.title = "\(newName) expires soon!"
    content.subtitle =
      "Expiration Date \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
    content.sound = .default

    let dateComponents = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute],
      from: reminderDate
    )
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: dateComponents,
      repeats: false
    )
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: trigger
    )

    try await notificationCenter.add(request)
  }

  private func newItem(
    newName: String,
    expirationDate: Date,
    purchaseDate: Date,
    quantity: Int16,
    measurement: String
  ) throws {
    let newItem = GroceryItem(context: viewContext)
    newItem.name = newName
    newItem.expirationDate = expirationDate
    newItem.purchasedDate = purchaseDate
    newItem.quantity = quantity
    newItem.measurement = measurement

    do {
      try viewContext.save()
    } catch {
      viewContext.delete(newItem)
      throw error
    }
  }
}

struct AddItemView_Previews: PreviewProvider {
  @State static var isShowing = false
  @State static var newName = ""
  @State static var date = Date()
  @State static var quantity = 1
  static var previews: some View {
    Group {
      AddItemView(
        isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date,
        quantity: quantity, measurement: newName
      )
      .preferredColorScheme(.dark)
      AddItemView(
        isPresented: $isShowing, newName: newName, expirationDate: date, purchaseDate: date,
        quantity: quantity, measurement: newName
      )
      .preferredColorScheme(.light)
    }
  }
}
