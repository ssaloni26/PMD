public class UserClass {
    public UserClass(){
        Id userId = '005gL000004oCi1QAE';
        User u = [
            SELECT Id, Name,userType, Username, Email, IsActive,
                   Profile.Name, UserRole.Name, Manager.Name,
                   TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey,
                   Alias, LastLoginDate, CreatedDate
            FROM User
            WHERE Id = :userId
        ];
        
        System.debug('Full Name: ' + u.Name);
        System.debug('User Type: ' + u.UserType);
        System.debug('Username: ' + u.Username);
        System.debug('Email: ' + u.Email);
        System.debug('Profile: ' + u.Profile.Name);
        System.debug('Role: ' + (u.UserRole != null ? u.UserRole.Name : 'No Role'));
        System.debug('Manager: ' + (u.Manager != null ? u.Manager.Name : 'No Manager'));
        System.debug('Alias: ' + u.Alias);
        System.debug('Time Zone: ' + u.TimeZoneSidKey);
        System.debug('Locale: ' + u.LocaleSidKey);
        System.debug('Language: ' + u.LanguageLocaleKey);
        System.debug('Last Login: ' + u.LastLoginDate);
        System.debug('Created On: ' + u.CreatedDate);
    }
}