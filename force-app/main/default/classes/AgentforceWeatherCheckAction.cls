public with sharing class AgentforceWeatherCheckAction {

    public class WeatherRequest {
        @InvocableVariable(required=true)
        public Decimal latitude;

        @InvocableVariable(required=true)
        public Decimal longitude;

        @InvocableVariable(required=true)
        public Datetime activityStartTime;
    }

    public class WeatherResponse {
        @InvocableVariable
        public Decimal rainProbability;

        @InvocableVariable
        public Boolean isUnsafe;
    }

    @InvocableMethod(
        label='Weather Safety Check'
        description='Determines if weather conditions are unsafe for the activity'
    )
    public static List<WeatherResponse> checkWeather(List<WeatherRequest> requests) {

        List<WeatherResponse> responses = new List<WeatherResponse>();

        for (WeatherRequest req : requests) {
            Decimal rainProbability = Math.mod(req.activityStartTime.hour() * 10, 100);
            Boolean isUnsafe = rainProbability > 70;

            WeatherResponse res = new WeatherResponse();
            res.rainProbability = rainProbability;
            res.isUnsafe        = isUnsafe;

            responses.add(res);
        }

        return responses;
    }
}