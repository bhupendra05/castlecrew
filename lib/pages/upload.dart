import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:geocoding/geocoding.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  bool isUploading = false;
  String postID = Uuid().v4();
  var file;
  var imagePath;
  handleTakePhoto() async {
    Navigator.pop(context);
    // ignore: invalid_use_of_visible_for_testing_member
    imagePath = await ImagePicker.platform
        .pickImage(source: ImageSource.camera, maxHeight: 675, maxWidth: 960);
    file = File(imagePath.path);
    setState(() {
      this.file = file;
    });
  }

  handleChoosFromGallery() async {
    Navigator.pop(context);
    // ignore: invalid_use_of_visible_for_testing_member
    imagePath =
        await ImagePicker.platform.pickImage(source: ImageSource.gallery);
    file = File(imagePath.path);

    setState(() {
      this.file = file;
    });
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                child: Text('Photo with Camera'),
                onPressed: () {
                  handleTakePhoto();
                },
              ),
              SimpleDialogOption(
                child: Text('Image from Gallery'),
                onPressed: handleChoosFromGallery,
              ),
              SimpleDialogOption(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 200.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
              onPressed: () => selectImage(context),
              child: Text(
                'Upload Image',
                style: TextStyle(color: Colors.white, fontSize: 18.0),
              ),
              color: Colors.deepOrange,
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  Future<String> uploadImage(imageFile) async {
    Reference fbstorage =
        FirebaseStorage.instance.ref().child('post_$postID.jpg');
    UploadTask uploadTask = fbstorage.putFile(imageFile);
    var downloadUrl;
    await uploadTask.whenComplete(() async {
      downloadUrl = await fbstorage.getDownloadURL();
    });
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    postsRef
        .doc(widget.currentUser.id)
        .collection('userPosts')
        .doc(postID)
        .set({
      "postId": postID,
      'ownerId': widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": Timestamp.now(),
      "likes": {}
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    var mediaUrl = await uploadImage(file);
    await createPostInFirestore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        description: captionController.text);
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postID = Uuid().v4();
    });
  }

  getUserLocation() async {
    setState(() {
      isUploading = true;
    });
    bool serviceEnabled;
    LocationPermission permission;

// Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return;
      }

      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return;
      }
    }

// When we reach here, permissions are granted and we can
// continue accessing the position of the device.
    Position _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    var lat = _position.latitude;
    var long = _position.longitude;
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
    Placemark placemark = placemarks[0];
    String formattedAddress = "${placemark.locality},${placemark.country}";
    locationController.text = formattedAddress;

    setState(() {
      isUploading = false;
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          onPressed: () {
            clearImage();
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
              onPressed: isUploading ? null : () => handleSubmit(),
              child: Text(
                "post",
                style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0),
              ))
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? circularProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          fit: BoxFit.cover, image: FileImage(file))),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                    hintText: "Write a Caption...", border: InputBorder.none),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                    hintText: "Where was this photo Taken?",
                    border: InputBorder.none),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              color: Colors.blue,
              onPressed: () {
                getUserLocation();
              },
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
            ),
          ),
        ],
      ),
    );
  }

  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
