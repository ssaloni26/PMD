/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-06-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ImpossibleTravelService {

        private static final Double EARTH_RADIUS_KM = 6371.0;
        private static final Double ROAD_SPEED_KMH   = 60.0;
        private static final Double FLIGHT_SPEED_KMH = 800.0;
    
        private static String formatDuration(Double hours) {
            if(hours == null) return null;
    
            Integer totalSeconds = Integer.valueOf(Math.round(hours * 3600));
            Integer h = totalSeconds / 3600;
            Integer m = Math.mod(totalSeconds, 3600) / 60;
            Integer s = Math.mod(totalSeconds, 60);
    
            if(h > 0) return h + 'h ' + m + 'm';
            else if(m > 0) return m + 'm';
            else return s + 's';
        }
        public class ImpossibleTravelInsight {
    
            public LoginHistory prevLogin;
            public LoginHistory currLogin;
    
            public String fromLocation;
            public String toLocation;
    
            public Double distanceKm;
            public Double actualHours;
            public Double requiredSpeedKmh;
    
            public Double expectedTravelHours;
    
    
            public ImpossibleTravelInsight(
                LoginHistory p,
                LoginHistory c,
                Double d,
                Double hrs,
                Double speed,
                Double expected
            ) {
                prevLogin = p;
                currLogin = c;
    
                fromLocation = (p.LoginGeo.City != null ? p.LoginGeo.City + ', ' : '') +
                               (p.LoginGeo.CountryIso != null ? p.LoginGeo.CountryIso : 'Unknown');
    
                toLocation   = (c.LoginGeo.City != null ? c.LoginGeo.City + ', ' : '') +
                               (c.LoginGeo.CountryIso != null ? c.LoginGeo.CountryIso : 'Unknown');
    
                distanceKm = d;
                actualHours = hrs;
                expectedTravelHours = expected;
                requiredSpeedKmh = speed;
            }
        }
    
        public static Double toRad(Double deg){
            return deg * Math.PI / 180;
        }
    
        public static Double distanceKm(Decimal lat1, Decimal lon1,
                                         Decimal lat2, Decimal lon2) {
    
            Double dLat = toRad((Double)lat2 - (Double)lat1);
            Double dLon = toRad((Double)lon2 - (Double)lon1);
    
            Double a =
                Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(toRad((Double)lat1)) *
                Math.cos(toRad((Double)lat2)) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
            Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return EARTH_RADIUS_KM * c;
        }
    
         public static List<ImpossibleTravelInsight> analyzeUser(string userId) {
    
            List<LoginHistory> logins = [
                SELECT UserId,Id, LoginTime,
                       LoginGeo.Latitude,
                       LoginGeo.Longitude,
                       LoginGeo.City,
                       LoginGeo.CountryIso
                FROM LoginHistory
                WHERE UserId = :userId                
                AND LoginGeo.Latitude != null
                AND LoginGeo.Longitude != null
                ORDER BY  LoginTime ASC
                LIMIT 1000
            ];

            List<ImpossibleTravelInsight> output = new List<ImpossibleTravelInsight>();
    
            for (Integer i = 1; i < logins.size(); i++) {
    
                LoginHistory prev = logins[i - 1];
                LoginHistory curr = logins[i];
                
                Long millis = curr.LoginTime.getTime() - prev.LoginTime.getTime();
                Double hours = millis / (1000.0 * 60 * 60);            
                if (millis<=0){continue;}
                
                Double distance = distanceKm(
                    prev.LoginGeo.Latitude,
                    prev.LoginGeo.Longitude,
                    curr.LoginGeo.Latitude,
                    curr.LoginGeo.Longitude
                );
    
                Double requiredSpeed = distance /hours;
    
                // Dynamic Travel Mode Logic
                  Double allowedSpeed = distance < 200 ? ROAD_SPEED_KMH : FLIGHT_SPEED_KMH;

    
                Double expectedHours = distance / allowedSpeed;
                // Expected time in milliseconds
                Double expectedMillis = expectedHours * 60 * 60 * 1000;
                
                // Flag if 2 × actual time <  expected time
                if (2 * millis <  expectedMillis) {
                    output.add(
                        new ImpossibleTravelInsight(
                            prev,
                            curr,
                            distance,
                            hours,
                            requiredSpeed,
                            expectedHours
                        )
                    );
                }
            }
    
            return output;
        }
        
        // Convert to Security_Insight__c
        public static List<Security_Insight__c> generateSecurityInsights(String userId) {
    
            List<ImpossibleTravelInsight> insights = analyzeUser(userId);
            List<Security_Insight__c> results = new List<Security_Insight__c>();
            User u = [
                SELECT Id, Name
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];
            
            String userName = u.Name;

            for (ImpossibleTravelInsight i : insights) {
            String prevTimeUtc = i.prevLogin.LoginTime.formatGMT('HH:mm \'UTC\'');
            String currTimeUtc = i.currLogin.LoginTime.formatGMT('HH:mm \'UTC\'');
                
           String description =
            u.Name +
            ' logged in from ' + i.fromLocation +
            ' at ' + prevTimeUtc +
          	' and then ' + i.toLocation + ' at ' + currTimeUtc  +'.'+
            'This sequence indicates a rapid geographic change within approximately ' +
            formatDuration(i.actualHours) + '. ' +
            'The travel distance of around ' + String.valueOf(Math.round(i.distanceKm)) +
            ' KM would require a speed of ' + String.valueOf(Math.round(i.requiredSpeedKmh)) + ' KM/H. ' + 
            'This normally requires at least ' + formatDuration(i.expectedTravelHours)+ ' . '   +
            ' based on an average travel speed of ' + (i.distanceKm < 200 ? ROAD_SPEED_KMH : FLIGHT_SPEED_KMH) + ' KM/H.';

            
            String recommendation =
                'Verify the user’s session history and enforce step-up authentication. ' +
                'Consider blocking sessions originating from unexpected geographies ' +
                'and configure IP login ranges or Conditional Access policies.';
            
            results.add(
                new Security_Insight__c(
                    User__c           = userId,
                    ResourceName__c   = userName,                         
                    Incident_Date__c  = i.currLogin.LoginTime.date(),      
                    Description__c    = description,
                    Severity__c       = 'High',
                    Name              = userName + ' Impossible Travel Detected', 
                    Recommendation__c = recommendation,
                    Operation__c      = 'Login'
                )
            );
          }
         return results;
    }
    
}