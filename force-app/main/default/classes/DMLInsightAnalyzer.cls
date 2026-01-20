/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-08-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class DMLInsightAnalyzer implements ISecurityAnalyzer {

    public String getRuleName() {
        return 'DML Operation Insight';
    }

    public String getCategory() {
        return 'DATABASE_OPERATION';
    }

    public Boolean isEnabled() {
        return true;
    }

    public String getQuery() {

        Set<Id> userIds = new Set<Id>();

        for (AggregateResult ar : [
            SELECT User__c userId
            FROM Database_Audit__c
            WHERE User__c != null
            AND LogDate__c >= LAST_N_MONTHS:6
            GROUP BY User__c
        ]) {
            userIds.add((Id) ar.get('userId'));
        }

        if (userIds.isEmpty()) {
            return 'SELECT Id FROM User WHERE Id = null';
        }

        List<String> userIdStrings = new List<String>();
        for (Id uid : userIds) {
            userIdStrings.add(String.valueOf(uid));
        } 

        return
            'SELECT Id, Name ' +
            'FROM User ' +
            'WHERE Id IN (\'' +
            String.join(userIdStrings, '\',\'') +
            '\')';
    }

    public List<SObject> getDeletedList() {
        List<SObject> deleteList = new List<SObject>();
        deleteList = [SELECT Id FROM Security_Insight__c WHERE ResourceType__c = 'Object'];
        return deleteList ;
    }

   public void evaluate(Boolean useAI, List<User> scope) {
       List<String> idList = new List<String>();
        for (User u : scope) idList.add(u.Id);

        String userIds = String.join(idList, ',');
        
        if (useAI) {
            createDMLInsightsWithAI(userIds);
        } else {
            createDMLInsightsWithAlgorithm(userIds);
        }
   }

    //chaining batch   
    public void finish(Map<String, Boolean> batchMap) {
        String nextbatch='LoginInsightAnalyzer';
        database.executeBatch(new SecurityAnalyzerBatch(nextbatch,batchMap,2),2);
    }
    public static void createDMLInsightsWithAI(String userIds) {
        String promptHandler = 'DatabaseAuditPromptHandler';
        
        String outputJSON = GenAIUtil.invokeAIPromptTemplate(userIds, promptHandler);

        outputJSON = cleanAIOutput(outputJSON);
        if (outputJSON =='[]') {
            System.debug('AI response is empty or invalid JSON. Skipping DML insight creation.');
            return;
        }
        List<ResponseWrapper> insights = (List<ResponseWrapper>) JSON.deserialize(outputJSON, List<ResponseWrapper>.class);
        List<Security_Insight__c> insightsToInsert = new List<Security_Insight__c>();
        for (ResponseWrapper wrapper : insights) {
            if (wrapper == null ||
            String.isBlank(wrapper.Id) ||
            String.isBlank(wrapper.InsightTitle) ||
            String.isBlank(wrapper.Insight) ||
            wrapper.IncidentDate == null ||
            String.isBlank(wrapper.Risk) ||
            String.isBlank(wrapper.Operation) ||
            String.isBlank(wrapper.ObjectName)||
            String.isBlank(wrapper.Recommendation)) {
            continue;
        	}
            
            Security_Insight__c si = new Security_Insight__c(
                Name = wrapper.InsightTitle,
                User__c = wrapper.Id,
                Description__c =EncodingUtil.urlDecode(wrapper.Insight, 'UTF-8').replaceAll('&#39;|&#x27;|&apos;', '\''),
                Incident_Date__c = wrapper.IncidentDate,
                Severity__c = wrapper.Risk,
                ResourceName__c = wrapper.ObjectName,
                ResourceType__c = 'Object',
                Recommendation__c = wrapper.Recommendation,
                Operation__c = wrapper.Operation
            );
            insightsToInsert.add(si);
        }
        if (!insightsToInsert.isEmpty()) {
            try {
                insert insightsToInsert;
                
            } catch (Exception e) {
                System.debug('Error inserting Security Insights: ' + e.getMessage());
            }}
    }
    

    public static void createDMLInsightsWithAlgorithm(String userIds) {
        List<ResponseWrapper> insights = detectSpikesAlgorithm(userIds);
        List<Security_Insight__c> insightsToInsert = new List<Security_Insight__c>();
        
        for (ResponseWrapper wrapper : insights) {
            Security_Insight__c si = new Security_Insight__c(
                Name = wrapper.InsightTitle,
                User__c = wrapper.Id,
                Description__c = wrapper.Insight,
                Incident_Date__c = wrapper.IncidentDate,
                Severity__c = wrapper.Risk,
                ResourceName__c = wrapper.ObjectName,
                ResourceType__c = 'Object',
                Recommendation__c = wrapper.Recommendation,
                Operation__c = wrapper.Operation
            );
            insightsToInsert.add(si);
        }
        
        if (!insightsToInsert.isEmpty()) insert insightsToInsert;
    }
@TestVisible
private static List<ResponseWrapper> detectSpikesAlgorithm(String userIds) {

    List<ResponseWrapper> insights = new List<ResponseWrapper>();

    /* ------------------------------------------------------------
     * 0. PARSE USER IDS
     * ------------------------------------------------------------ */
    List<Id> userIdList = new List<Id>();
    if (String.isNotBlank(userIds)) {
        for (String s : userIds.split(',')) {
            userIdList.add((Id) s.trim());
        }
    }
    /* ------------------------------------------------------------
     * 1. FETCH FULL AUDIT HISTORY (ORDERED)
     * ------------------------------------------------------------ */
    List<Database_Audit__c> audits = [
        SELECT User__c,
               User__r.Name,
               ObjectName__c,
               Operation__c,
               Record_Count__c,
               LogDate__c
        FROM Database_Audit__c
        WHERE User__c IN :userIdList
          AND LogDate__c >= LAST_N_MONTHS:6
        ORDER BY User__c, ObjectName__c, Operation__c, LogDate__c
    ];

    if (audits.isEmpty() || userIdList.isEmpty()) return insights;

    /* ------------------------------------------------------------
     * 2. GROUP BY USER + OBJECT + OPERATION
     * ------------------------------------------------------------ */
    Map<String, List<Database_Audit__c>> groupedAudits = new Map<String, List<Database_Audit__c>>();

    for (Database_Audit__c a : audits) {
        String key = a.User__c + '|' + a.ObjectName__c + '|' + a.Operation__c;
        if (!groupedAudits.containsKey(key)) {
            groupedAudits.put(key, new List<Database_Audit__c>());
        }
        groupedAudits.get(key).add(a);
    }

    /* ------------------------------------------------------------
     * 3. ANALYZE EACH GROUP SEQUENTIALLY
     * ------------------------------------------------------------ */
    for (String key : groupedAudits.keySet()) {

        List<Database_Audit__c> records = groupedAudits.get(key);    

        Decimal total = 0;
        Decimal maxCount = 0;
        Decimal maxJump = 0;
        Decimal prev = null;

        for (Database_Audit__c r : records) {
            Decimal curr = r.Record_Count__c;
            total += curr;

            if (curr > maxCount) {
                maxCount = curr;
            }

            if (prev != null && prev > 0) {
                Decimal jump = curr / prev;
                if (jump > maxJump) {
                    maxJump = jump;
                }
            }

            prev = curr;
        }
        Decimal avgCount = total / records.size();
        Integer totalEvents = records.size();

        /* ------------------------------------------------------------
         * 4. RISK CLASSIFICATION
         * ------------------------------------------------------------ */
        String risk;
         String severityPhrase;

        if (totalEvents == 1) {
            severityPhrase='Abnormal';
            if (maxCount >= 1000)       risk = 'High';
            else if (maxCount >= 500)   risk = 'Medium';
            else if (maxCount >= 100)   risk = 'Low';
        } else {
            Decimal multiplier = (avgCount > 0) ? (maxCount / avgCount) : 0;

            if (multiplier >= 10 || maxJump >= 5)     {  risk = 'High'; severityPhrase = 'dramatically higher than normal activity';
            }
            else if (multiplier >= 5 || maxJump >= 3)   {risk = 'Medium'; severityPhrase = 'significantly higher than usual activity';
            }
            else if (multiplier >= 2 || maxJump >= 2)   {risk = 'Low'; severityPhrase = 'about twice the user’s normal activity';
            }
    }
        
        if (risk == null || records == null || records.isEmpty() || maxCount < 100) continue;
       
        /* ------------------------------------------------------------
         * 5. CREATE SINGLE INSIGHT
         * ------------------------------------------------------------ */
        Database_Audit__c last = records[records.size() - 1];

        ResponseWrapper rw = new ResponseWrapper();
        rw.Id = last.User__c;
        rw.ObjectName = last.ObjectName__c;
        rw.Operation = last.Operation__c;
        rw.Risk = risk;
        rw.IncidentDate = last.LogDate__c;

        rw.InsightTitle = risk + '-Volume ' + rw.Operation + ' of ' + rw.ObjectName + 'Records by ' + last.User__r.Name ;
    
        rw.Insight =
        'User ' + last.User__r.Name +
        ' executed ' + maxCount.setScale(0) + ' records ' + rw.Operation +
        ' on ' + rw.ObjectName +
        ' on ' + String.valueOf(rw.IncidentDate) + '. ' +
        'This activity is ' + severityPhrase +
        ' compared to their historical behavior.';

        insights.add(rw);
    }
    return insights;
}
// --- Clean AI Output ---

    @TestVisible
    private static String cleanAIOutput(String raw) {
        if (String.isBlank(raw)) {
            System.debug('AI response is blank. Returning empty list.');
            return '[]';
        }
    
        // Step 1: Normalize
        String cleaned = raw.replace('\u00A0', ' ')
                            .replaceAll('(?i)json', '')
            				.replaceAll('(?i)', '')
                            .trim();
    
        // Step 2: Remove leading "json" text if present
        if (cleaned.toLowerCase().startsWith('json')) {
            cleaned = cleaned.substring(4).trim();
        }
    
        // Step 3: Check if the cleaned string is valid JSON
        if (!(cleaned.startsWith('[') || cleaned.startsWith('{'))) {
            System.debug('AI response is invalid JSON after cleaning. Skipping DML insight creation.');
            return '[]';
        }
    
        return cleaned;
    }

   	 
     // --- Wrapper for JSON Parsing ---
    public class ResponseWrapper {
        public String Id;
        public Date IncidentDate;
        public String ObjectName;
        public String Operation;
        public String Insight;
        public String Risk;
        public String InsightTitle;
        public String Recommendation;
    } 
}