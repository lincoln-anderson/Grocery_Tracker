import SwiftUI

struct RecipeScreen: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RecipeItem.createdDate, ascending: true)],
        animation: .default)
    private var recipes: FetchedResults<RecipeItem>
    
    
    var body: some View {
        VStack {
            Text("Recipes")
                .font(.largeTitle)
                .padding()
            Text("\(recipes.count)")
                .font(.largeTitle)
                .padding()
            Text("This is the main recipe screen. Add more content here.")
                .foregroundColor(.secondary)
            Button(action: addRecipe) {
                Text("Add Recipe")
            }
            ForEach(recipes, id: \.createdDate) { recipe in
                    Text(recipe.name ?? "No name")
                    Text(recipe.instructions ?? "No instructions")
            }
        }
    }
    func addRecipe() {
        let newRecipe = RecipeItem(context: viewContext)
        print("newRecipe")
        print(newRecipe)
        newRecipe.name = "Test Recipe"
        newRecipe.createdDate = Date()
        newRecipe.instructions = "cook chicken"
        print(newRecipe)
        
        try? viewContext.save()
    }
}

#Preview {
    RecipeScreen()
}
