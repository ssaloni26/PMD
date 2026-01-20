global class apex1 extends apex2 {
    global override String sayHello() {
        return 'Hello from Apex';
    }

    global String callParentMethod() {
        return super.sayHello();
    }
}