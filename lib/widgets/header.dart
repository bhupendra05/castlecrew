import 'package:flutter/material.dart';

var height;
AppBar header(context,
    {bool isAppTitle = false, String titleText, removeBackButton = false}) {
  height = MediaQuery.of(context).size.height;
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? "CastleCrew" : titleText,
      style: TextStyle(
          color: Colors.white,
          fontFamily: isAppTitle ? "Signatra" : "",
          fontSize: isAppTitle ? height * 0.044 : height * 0.03),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
    actions: [
      IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.bento_rounded,
            size: 34,
          ))
    ],
  );
}
