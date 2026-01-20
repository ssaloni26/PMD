public class WireDecorator {
    @AuraEnabled(Cacheable = true)
    public static string  showMessage(){
        system.debug('hii we are learning Wire Decorator');
        return '07777777777777777777hii';
    }

}