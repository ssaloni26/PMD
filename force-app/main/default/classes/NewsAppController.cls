public with sharing class NewsAppController {
   
    @AuraEnabled(cacheable=true)
    public static List<NewsArticle> retriveNews(String category) {
        List<NewsArticle> newsList = new List<NewsArticle>();
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
           
           
            String endpoint = 'https://newsapi.org/v2/top-headlines?country=us&apiKey=3c10833fa8d94e5f9d96796120b77f46';
           
           
            if (!String.isBlank(category)) {
                endpoint += '&category=' + category.toLowerCase();
            }
           
            req.setEndpoint(endpoint);
            req.setMethod('GET');
           
            HttpResponse res = http.send(req);
           
            System.debug(' News API Status Code: ' + res.getStatusCode());
            System.debug('️ News API Response: ' + res.getBody());
           
            if (res.getStatusCode() == 200) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
               
                 
                if (results.containsKey('status') && (String)results.get('status') == 'ok') {
                   
                    if (results.containsKey('articles')) {
                            List<Object> articles = (List<Object>) results.get('articles');
                        for (Object art : articles) {
                            Map<String, Object> a = (Map<String, Object>) art;
                            NewsArticle n = new NewsArticle();
                           
                            n.title = a.containsKey('title') ? (String)a.get('title') : 'No Title';
                            n.description = a.containsKey('description') ? (String)a.get('description') : 'No Description';
                            n.url = a.containsKey('url') ? (String)a.get('url') : '';
                            n.imageUrl = a.containsKey('urlToImage') ? (String)a.get('urlToImage') : '';
                           
                            newsList.add(n);
                        }
                    } else {
                        System.debug('No articles key in API response');
                    }
                   
                } else {
                    System.debug('News API returned error status: ' + results.get('status'));
                }
               
            } else {
                System.debug('️ News API returned non-200 status: ' + res.getStatusCode() + ' ' + res.getBody());
            }
           
        } catch (Exception e) {
            System.debug('️ Exception while fetching news: ' + e.getMessage());
        }
       
        return newsList;
    }
   
    public class NewsArticle {
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String url;
        @AuraEnabled public String imageUrl;
    }
}