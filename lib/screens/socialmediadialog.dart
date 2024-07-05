import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Follow us on social media:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialMediaButton(
                  imageAsset: 'assets/images/telegram.png',
                  onPressed: _launchtelegram,
                ),
                SizedBox(width: 16),
                SocialMediaButton(
                  imageAsset: 'assets/images/x.png',
                  onPressed: _launchtwitter,
                ),
                SizedBox(width: 16),
                SocialMediaButton(
                  imageAsset: 'assets/images/website.png',
                  onPressed: _launchwebsite,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _launchwebsite() async {
  const url = 'https://hideprotocol.com/';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

void _launchtwitter() async {
  const url = 'https://x.com/HideProtocol';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

void _launchtelegram() async {
  const url = 'https://t.me/hideprotocol';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class SocialMediaButton extends StatelessWidget {
  final String imageAsset;
  final VoidCallback? onPressed;

  const SocialMediaButton({
    required this.imageAsset,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(
        imageAsset,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      ),
    );
  }
}
