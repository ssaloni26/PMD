public with sharing class NewsAPIService {
    private static final String API_KEY = 'YOUR_API_KEY'; // Replace with NewsAPI key
    private static final String BASE_URL = 'https://newsapi.org/v2/top-headlines';

    @AuraEnabled(cacheable=true)
    public static String getNews(String country, String category) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(BASE_URL + '?apiKey=' + API_KEY + '&country=' + country + '&category=' + category);
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            throw new AuraHandledException('Error from API: ' + response.getStatus());
        }
    }
}