public with sharing class circle extends shape{
    Decimal radius;
    public circle(Decimal r ) {
        radius=r;
    }
    
    public override Decimal area() {
        return 3.14 * radius * radius;
    }
}