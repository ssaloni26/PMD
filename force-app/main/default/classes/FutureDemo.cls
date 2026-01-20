public class FutureDemo {
    
	public void invokeFutureCall(){
        String primitiveValue = 'Input to future method';
        List<String> listofPrimitiveValue = new List<String>{primitiveValue};
        //Account accountRec = [Select Id, Name From Account Limit 1][0]; 
        //System.debug('accountList:+ accountRec);
        
        futureMethod1();
        
        futureMethod2();
        futureMethod3();
    } 

    @future(callout = true)
    public static void futureMethod1() {
        System.debug('Inside futureMethod1');
        //System.debug('inputParam: ' + inputParam);
    }
    @future
    public static void futureMethod2() {
        
        System.debug('Inside futureMethod2');
    }
    @future
    public static void futureMethod3(){ 
        System.debug('Inside futureMethod3');
    }
}