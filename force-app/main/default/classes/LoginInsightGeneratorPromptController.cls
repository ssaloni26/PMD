/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-09-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class LoginInsightGeneratorPromptController {
    @TestVisible
    private static List<LoginHistory> mockLoginHistoryList;

    @InvocableMethod(label='Get Login History for AI Analysis')
    public static List<Response> getPrompt(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Set<Id> userIds = new Set<Id>();

        for (Request r : requests) {
            if (String.isNotBlank(r.User_Id)) {
                for (String idStr : r.User_Id.split(',')) {
                    if (isValidId(idStr)) userIds.add(Id.valueOf(idStr.trim()));
                }
            }
        }

        if (userIds.isEmpty()) {
            Response emptyResp = new Response();
            emptyResp.Prompt = '[]';
            responses.add(emptyResp);
            return responses;
        }

        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :userIds]);
        DateTime startDate = DateTime.now().addMonths(-6);

        List<LoginHistory> loginHistoryList = (Test.isRunningTest() && mockLoginHistoryList != null)
            ? mockLoginHistoryList
            : [SELECT UserId, LoginTime, Status, SourceIp, LoginGeo.City, LoginGeo.Country
               FROM LoginHistory
               WHERE UserId IN :userIds
               AND LoginTime >= :startDate
               ORDER BY UserId, LoginTime ASC];

        List<Map<String, Object>> allLoginData = new List<Map<String, Object>>();

        for (LoginHistory log : loginHistoryList) {
            User u = userMap.get(log.UserId);
            allLoginData.add(new Map<String, Object>{
                'UserId'    => log.UserId,
                'UserName'  => u != null ? u.Name : 'Unknown User',
                'ToCity'    => (log.LoginGeo != null && String.isNotBlank(log.LoginGeo.City)) ? log.LoginGeo.City : null,
                'ToCountry' => (log.LoginGeo != null && String.isNotBlank(log.LoginGeo.Country)) ? log.LoginGeo.Country : null,
                'LoginTime' => log.LoginTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
                'Status'    => log.Status,
                'SourceIp'  => log.SourceIp
            });
        }
        List<AuthSession> authSessionList = [
            SELECT Id, UsersId, LoginType, SessionType,
                   SourceIp, LoginGeo.City, LoginGeo.Country,
                   CreatedDate, LastModifiedDate
            FROM AuthSession
            WHERE UsersId IN :userIds and sessionType != 'UnspecifiedType'
            ORDER BY LastModifiedDate DESC
        ];

        for (AuthSession asn : authSessionList) {
            User u = userMap.get(asn.UsersId);

            allLoginData.add(new Map<String, Object>{
                'UserId'       => asn.UsersId,
                'UserName'     => u != null ? u.Name : 'Unknown User',
                'ToCity'       => (asn.LoginGeo != null && String.isNotBlank(asn.LoginGeo.City)) ? asn.LoginGeo.City : null,
                'ToCountry'    => (asn.LoginGeo != null && String.isNotBlank(asn.LoginGeo.Country)) ? asn.LoginGeo.Country : null,
                'LoginTime'    => asn.LastModifiedDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
                'Status'       => asn.SessionType + ' / ' + asn.LoginType,
                'SourceIp'     => asn.SourceIp
            });
        }
        Response output = new Response();
        output.Prompt = JSON.serialize(allLoginData);
        responses.add(output);
        return responses;
    }

    private static Boolean isValidId(String s) {
        try { Id.valueOf(s); return true; } catch (Exception e) { return false; }
    }

    public class Request { @InvocableVariable(required=true) public String User_Id; }
    public class Response { @InvocableVariable public String Prompt; }
}