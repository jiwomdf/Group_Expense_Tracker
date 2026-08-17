# Group Expense Tracker
Group Expense Tracker is a Flutter group expense tracker app originally developed for my family’s use, which now I decided to make it open source. The app is designed to simplify tracking expense and enable effortless sharing of expenses among multiple users. It is available across **Android**, **iOS**, and **Web platforms**.


<image src="assets/record.gif" width="140" height="280"> </image>
<image src="https://github.com/jiwomdf/group_expense_tracker/blob/main/github_assets/ios.png" width="140" height="280"> </image>
<image src="https://github.com/jiwomdf/group_expense_tracker/blob/main/github_assets/white_ios.png" width="140" height="280"> </image>
<image src="https://github.com/jiwomdf/group_expense_tracker/blob/main/github_assets/web.png" width="300" height="280"> </image> 


<br />

## Web link
Firebase hosting link <br />
https://group-expense-tracker.web.app/ <br /><br />

## Feature
- Insert and Update expense, category, ect data
- Insert data can be together as group
- Modify firestore scheme
- Export to Json and Spread Sheets
- Monthly budget, stored on the device only
- Light and Dark theme <br /><br />


## App Stack 🏗️
The app use Firestore, Firebase Auth, Firebase Cloud Messaging, and Crashlytics. Also the app has been thoroughly tested using bloc_test to ensure reliability and performance.
- Bloc
- Firebase Auth
- Fire Store
- Crashlytic
- Cloud Messaging
- Dio
- Fl Chart
- Get It <br /><br />

## How to change the app Firebase project
#### This app depends on Firebase Auth and Firestore, so you need to add your own Firebase project as stated below
- Create your own firebase project and register the Android, iOS, and Web
- open the `google-services.json` for Android, `GoogleService-Info.plist` for iOS, and `firebaseConfig` for web
- you can see the credential of the firebase options inside those files, you can input it to the first config firebase option screen <br>
<image src="https://github.com/jiwomdf/group_expense_tracker/blob/main/github_assets/foptions.png" width="300" height="280"> </image> <br>
- Enable Firebase Auth by email and password
- Enable Firestore and set the rules to `allow read, write: if request.auth != null;`
- After all the setup, then run the app smoothly 🥳

it also open for contribution and discussion 🙏
<br><br>
