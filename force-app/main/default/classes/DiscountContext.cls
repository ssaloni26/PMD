/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class DiscountContext {
    private DiscountStrategy strategy;

    // Constructor Injection (Dependency Injection)
    public DiscountContext(DiscountStrategy strategy) {
        this.strategy = strategy;
    }

    public Decimal apply(Decimal amount) {
        return strategy.applyDiscount(amount);
    }
}