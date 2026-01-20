/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-05-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class myclass implements MyInterface {
    
    public void doWork(String input) {
        System.debug('Doing work with: ' + input);
    }

    public Integer calculate(Integer a, Integer b) {
        return a + b;
    }
}