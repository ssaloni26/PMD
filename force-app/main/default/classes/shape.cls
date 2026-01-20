public with sharing  abstract class shape {
    public abstract Decimal area();

    public void describe(){
        System.debug('This is a shape');
    }
}