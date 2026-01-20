public class StaticDemo {

    public String helloWorldString;						//Instance  Member Variables
    private static final String DEFAULT_STRING;		//Static  Member Variables
    
    static{
   		DEFAULT_STRING = 'Hello World';				//Static Initializer Blocks
    }
    
    public StaticDemo(){                     		//Constructor
    	this(DEFAULT_STRING  );
    }
    
    public StaticDemo(String stringToDisplay) {     //Overloading Constructor
    this.helloWorldString = stringToDisplay;
    }
    
    public void printOutput(){				//Instance Method
    	System.debug('Display text: ' + helloWorldString);
    }
    
    public static void printOutput1(){				//Static Method
    	System.debug('static ');
    }
}