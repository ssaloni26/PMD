/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class RegularDiscount implements DiscountStrategy {
    public Decimal applyDiscount(Decimal amount) {
        return amount * 0.90; // 10% discount
    }
}