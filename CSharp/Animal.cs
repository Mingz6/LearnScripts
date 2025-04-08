/// <summary>
/// Base interface that all animal types must implement
/// </summary>
public interface IAnimal 
{
    string Name { get; set; }
    string MakeSound();
}

/// <summary>
/// Cat implementation of IAnimal
/// </summary>
public class Cat : IAnimal 
{
    public string Name { get; set; } = "Unknown Cat";
    public string MakeSound() => "Meow!";
    public void Purr() => Console.WriteLine($"{Name} is purring...");
}

/// <summary>
/// Dog implementation of IAnimal
/// </summary>
public class Dog : IAnimal 
{
    public string Name { get; set; } = "Unknown Dog";
    public string MakeSound() => "Woof!";
    public void Fetch() => Console.WriteLine($"{Name} is fetching a ball!");
}

/// <summary>
/// Non-generic base interface for all animal services
/// This allows for polymorphic handling of different animal services
/// </summary>
public interface IAnimalService
{
    string GetServiceName();
    void DisplayServiceInfo();
}

/// <summary>
/// Generic interface that inherits from the non-generic base
/// Provides type-specific operations for each animal type
/// </summary>
public interface IAnimalService<T> : IAnimalService where T : class, IAnimal
{
    T GetAnimal();
    void HandleAnimal(T animal);
}

/// <summary>
/// Service implementation for Cat type
/// </summary>
public class CatService : IAnimalService<Cat>
{
    public string GetServiceName() => "Cat Care Service";
    
    public void DisplayServiceInfo() => 
        Console.WriteLine("This service specializes in cat care and handling");
    
    public Cat GetAnimal() => new Cat { Name = "Whiskers" };
    
    public void HandleAnimal(Cat cat)
    {
        Console.WriteLine($"Handling cat named {cat.Name}");
        Console.WriteLine($"Cat says: {cat.MakeSound()}");
        cat.Purr(); // Cat-specific method
    }
}

/// <summary>
/// Service implementation for Dog type
/// </summary>
public class DogService : IAnimalService<Dog>
{
    public string GetServiceName() => "Dog Care Service";
    
    public void DisplayServiceInfo() => 
        Console.WriteLine("This service specializes in dog care and training");
    
    public Dog GetAnimal() => new Dog { Name = "Rex" };
    
    public void HandleAnimal(Dog dog)
    {
        Console.WriteLine($"Handling dog named {dog.Name}");
        Console.WriteLine($"Dog says: {dog.MakeSound()}");
        dog.Fetch(); // Dog-specific method
    }
}

/// <summary>
/// Factory pattern implementation to resolve the correct service based on animal type
/// </summary>
public class AnimalServiceResolver
{
    public IAnimalService Resolve(string animalType)
    {
        return animalType.ToLower() switch
        {
            "cat" => new CatService(),
            "dog" => new DogService(),
            _ => throw new ArgumentException($"Unknown animal type: {animalType}")
        };
    }
}

/// <summary>
/// Usage example class that demonstrates how to use the animal services
/// </summary>
public class AnimalServiceDemo
{
    public static void RunDemo()
    {
        // Create the resolver
        var resolver = new AnimalServiceResolver();
        
        // Demonstrate handling a cat
        Console.WriteLine("=== Cat Example ===");
        var catService = resolver.Resolve("cat");
        catService.DisplayServiceInfo();
        
        // We need to cast to use type-specific methods
        if (catService is IAnimalService<Cat> typedCatService)
        {
            var cat = typedCatService.GetAnimal();
            typedCatService.HandleAnimal(cat);
        }
        
        Console.WriteLine();
        
        // Demonstrate handling a dog
        Console.WriteLine("=== Dog Example ===");
        var dogService = resolver.Resolve("dog");
        dogService.DisplayServiceInfo();
        
        // We need to cast to use type-specific methods
        if (dogService is IAnimalService<Dog> typedDogService)
        {
            var dog = typedDogService.GetAnimal();
            typedDogService.HandleAnimal(dog);
        }
    }
}