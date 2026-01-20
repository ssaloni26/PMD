public class HttpCalloutWrapper {

    // Map to keep track of callout counts per class for current transaction
    private static Map<String, Integer> calloutCounts = new Map<String, Integer>();

    /**
     * Sends HTTP request and logs debug info
     */
    public static HttpResponse send(HttpRequest req, String callingClassName) {
        Http h = new Http();
        HttpResponse res = h.send(req);

        // --- Update callout count ---
        if (!calloutCounts.containsKey(callingClassName)) {
            calloutCounts.put(callingClassName, 0);
        }
        calloutCounts.put(callingClassName, calloutCounts.get(callingClassName) + 1);

        // --- Debug info ---
        System.debug('HTTP Callout made by Class: ' + callingClassName
                     + ', Date: ' + Date.today()
                     + ', Total callouts so far in this transaction: ' + calloutCounts.get(callingClassName));

        return res;
    }

    /**
     * Optional: Get all callout counts in the current transaction
     */
    public static Map<String, Integer> getCalloutCounts() {
        return calloutCounts;
    }
}