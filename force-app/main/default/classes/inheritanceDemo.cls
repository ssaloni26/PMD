public with sharing class inheritanceDemo {

    public virtual class Vehicle {
        public void start() {
            System.debug('hiiii');
        }
    }

    public class Bike extends Vehicle {
        public void debug() {
            System.debug('bike');
        }
    }

    public void run() {
        Bike b = new Bike();
        b.start();
        b.debug();
    }

}