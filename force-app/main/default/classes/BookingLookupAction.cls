public class BookingLookupAction {
   public static String getRefundMessage(String activityType, Datetime startTime, Datetime cancellationTime) {
        Long hoursBefore = startTime.getTime() - cancellationTime.getTime();
        hoursBefore = hoursBefore / (1000 * 60 * 60); // convert milliseconds to hours

        Map<String, List<String>> policies = new Map<String, List<String>>{
            'Kayaking' => new List<String>{'Free up to 24h', '50% within 12-24h', 'No refund <12h'},
            'Trekking' => new List<String>{'Free up to 48h', 'No refund after'},
            'Cycling Tour' => new List<String>{'Free up to 12h', '25% after'},
            'Outdoor Yoga' => new List<String>{'Free up to 3h', 'Full charge after'}
        };

        List<String> activityPolicy = policies.get(activityType);
        if(activityPolicy == null) return 'No policy found';

        if(activityType == 'Trekking' && hoursBefore >= 48) return 'Free cancellation allowed';
        if(activityType == 'Trekking' && hoursBefore < 48) return 'No refund applicable';
        // Add other activities similarly
        return 'Check policy manually';
    }

}