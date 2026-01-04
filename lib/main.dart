import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase Initialize ചെയ്യുമ്പോൾ നിങ്ങളുടെ URL ഇവിടെ നൽകുക
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAthFMO8zGT5BtiOkh4zkc71jL06LR_F9c",
      appId: "1:your_app_id", // നിങ്ങളുടെ Firebase App ID നൽകുക
      messagingSenderId: "sender_id",
      projectId: "a-one-chat-19ad6",
      databaseURL: "https://a-one-chat-19ad6-default-rtdb.firebaseio.com",
    ),
  );
  runApp(AOneMusic());
}

class AOneMusic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: LoginPage(),
    );
  }
}

// --- ലോഗിൻ പേജ് ---
class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("A One Music - Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Password"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Login"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => MusicHomePage()));
              },
            )
          ],
        ),
      ),
    );
  }
}

// --- ഹോം പേജ് (പാട്ട് പ്ലേ ചെയ്യാനും അപ്‌ലോഡ് ചെയ്യാനും) ---
class MusicHomePage extends StatefulWidget {
  @override
  _MusicHomePageState createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final cloudinary = CloudinaryPublic('dcsczlahu', 'ml_default', cache: false);
  final databaseRef = FirebaseDatabase.instance.ref("songs");

  // പാട്ട് സെലക്ട് ചെയ്ത് Cloudinary-ലേക്ക് അപ്‌ലോഡ് ചെയ്യാനുള്ള ഫങ്ക്ഷൻ
  Future<void> uploadSong() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    
    if (result != null) {
      String filePath = result.files.single.path!;
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(filePath, resourceType: CloudinaryResourceType.Auto),
        );
        
        // Firebase-ലേക്ക് ലിങ്ക് സേവ് ചെയ്യുന്നു
        await databaseRef.push().set({
          "name": result.files.single.name,
          "url": response.secureUrl,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Song Uploaded!")));
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("A One Music")),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadSong,
        child: Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && (snapshot.data! as DatabaseEvent).snapshot.value != null) {
            Map<dynamic, dynamic> map = (snapshot.data! as DatabaseEvent).snapshot.value as Map;
            List songs = map.values.toList();
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(songs[index]['name']),
                  leading: Icon(Icons.music_note),
                  onTap: () async {
                    await audioPlayer.play(UrlSource(songs[index]['url']));
                  },
                );
              },
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

