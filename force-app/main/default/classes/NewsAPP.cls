public with sharing class NewsAPP {

    public class NewsArticle {
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public String urlToImage { get; set; }

        public NewsArticle(String t, String d, String u, String i) {
            this.title = t;
            this.description = d;
            this.url = u;
            this.urlToImage = i;
        }
        public NewsArticle() {}
    }

    @AuraEnabled(cacheable=true)
    public static List<NewsArticle> getNewsMock(String category) {
        List<NewsArticle> newsList = new List<NewsArticle>();
        newsList.add(new NewsArticle('Breaking News','Description 1','https://example.com','https://via.placeholder.com/300'));
        newsList.add(new NewsArticle('Tech Update','Description 2','https://example.com','https://via.placeholder.com/300'));
        newsList.add(new NewsArticle('Market Insights','Description 3','https://example.com','https://via.placeholder.com/300'));
        return newsList;
    }
}