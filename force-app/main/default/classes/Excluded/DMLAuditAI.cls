/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-21-2026
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class DMLAuditAI {
  @AuraEnabled
  public static String getAISpikeAlert(
    String userName,
    String objectName,
    Decimal currentCount,
    Decimal historicalAvg,
    Decimal thresholdFactor,
    String customPrompt
  ) {
    if (historicalAvg == null)
      historicalAvg = 0;
    if (thresholdFactor == null || thresholdFactor <= 0)
      thresholdFactor = 2;

    String message;

    if (currentCount > historicalAvg * thresholdFactor) {
      message =
        'DML spike detected: Count ' +
        currentCount +
        ', Overall Avg ' +
        historicalAvg +
        ', Threshold Factor ' +
        thresholdFactor +
        'x, ' +
        'User: ' +
        userName +
        ', Object: ' +
        objectName;
    } else {
      message =
        'No spike detected. Count ' +
        currentCount +
        ' is within threshold (' +
        (historicalAvg * thresholdFactor) +
        ') for User: ' +
        userName +
        ', Object: ' +
        objectName;
    }

    // Append custom prompt if provided
    if (String.isNotBlank(customPrompt)) {
      message += '\n\nCustom Prompt: ' + customPrompt;
    }

    return message;
  }
  @AuraEnabled
  public static String getAISpikeAlert(
    String userName,
    String objectName,
    Decimal currentCount,
    Decimal historicalAvg,
    Decimal thresholdFactor,
    String customPrompt
  ) {
    if (historicalAvg == null)
      historicalAvg = 0;
    if (thresholdFactor == null || thresholdFactor <= 0)
      thresholdFactor = 2;

    String message;

    if (currentCount > historicalAvg * thresholdFactor) {
      message =
        'DML spike detected: Count ' +
        currentCount +
        ', Overall Avg ' +
        historicalAvg +
        ', Threshold Factor ' +
        thresholdFactor +
        'x, ' +
        'User: ' +
        userName +
        ', Object: ' +
        objectName;
    } else {
      message =
        'No spike detected. Count ' +
        currentCount +
        ' is within threshold (' +
        (historicalAvg * thresholdFactor) +
        ') for User: ' +
        userName +
        ', Object: ' +
        objectName;
    }

    // Append custom prompt if provided
    if (String.isNotBlank(customPrompt)) {
      message += '\n\nCustom Prompt: ' + customPrompt;
    }

    return message;
  }
}
