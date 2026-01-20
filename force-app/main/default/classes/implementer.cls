public with sharing class implementer implements interdemo1,interdemo2 {

    public void interdemo1() {
        System.debug('Method One from InterfaceOne');
    }

    public void interdemo2() {
        System.debug('Method Two from InterfaceTwo');
    }

    public void run() {
        interdemo1();
        interdemo2();
    }
}