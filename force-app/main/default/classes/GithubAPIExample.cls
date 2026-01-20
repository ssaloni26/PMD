public class GithubAPIExample {

    public class GithubUserWrapper {
        public String login;
        public String name;
        public String company;
    }

    public static void getGithubUser(String username) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.github.com/users/' + username);
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            GithubUserWrapper responseWrapper = 
                (GithubUserWrapper) JSON.deserialize(res.getBody(), GithubUserWrapper.class);
            System.debug('Login: ' + responseWrapper.login);
            System.debug('Name: ' + responseWrapper.name);
            System.debug('Company: ' + responseWrapper.company);
        } else {
            System.debug('Error: ' + res.getStatus());
        }
    }
}