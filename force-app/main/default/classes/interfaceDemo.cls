public class interfaceDemo {

    public interface in1 {
        void write();
    }
    public interface in2 {
        void start(); 
    }

    public class Bike implements in1,in2 {
        public void debug() {
            System.debug('bike');
        }
        public void write() {
            System.debug('byyyyyyyyy');
        }

        public void start() {
            System.debug('hiiii');
        }

        
    }

    public void run() {
        Bike b = new Bike();
        b.write();
        b.start();
        b.debug();
}

}