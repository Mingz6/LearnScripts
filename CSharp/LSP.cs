// This C# file demonstrates the Liskov Substitution Principle (LSP) from SOLID principles. It defines an abstract class Bird with an Eat method, and an interface IFlyable for flying behavior. The Sparrow class inherits from Bird and implements IFlyable, meaning it can eat and fly. The Penguin class inherits from Bird but does not implement IFlyable, reflecting that penguins cannot fly. This design avoids forcing all birds to have a Fly method, respecting the LSP by ensuring subclasses can be substituted for their base class without unexpected behavior.
// 抽象鸟类，不包含飞行行为
public abstract class Bird
{
    public abstract void Eat();
}

// 飞行能力接口
public interface IFlyable
{
    void Fly();
}

// 实现了飞行的鸟
public class Sparrow : Bird, IFlyable
{
    public override void Eat()
    {
        Console.WriteLine("Sparrow is eating.");
    }

    public void Fly()
    {
        Console.WriteLine("Sparrow is flying.");
    }
}

// 不会飞的鸟
public class Penguin : Bird
{
    public override void Eat()
    {
        Console.WriteLine("Penguin is eating.");
    }

    // 没有 Fly 方法，也不会飞
}
