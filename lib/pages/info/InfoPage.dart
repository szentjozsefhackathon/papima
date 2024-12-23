import 'package:PapIma/common/launch_url.dart';
import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Információk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'PapIma Alkalmazás',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Ez az alkalmazás segíti a Magyar Katolikus Egyház papjaiért való imádkozást. A papokat a nyilvános sematizmusból nyerjük. Jelenleg azt az imaformát támogatja az alkalmazás, hogy elkezdi a papokat "végigimádkozni" az elejéről és a haladást nyomonköveti az alkalmazás. Az alkalmazás nem oszt meg adatokat.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Divider(),
            Text(
              'Hasznos hivatkozások',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.link, color: Colors.blue),
              title: Text(
                'GitHub projekt',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                launch_url('https://github.com/szentjozsefhackathon/papima');
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: Colors.green),
              title: Text(
                'Sematizmus (Forrás)',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                launch_url('https://szentjozsefhackathon.github.io/sematizmus');
              },
            ),
            ListTile(
              leading: Icon(Icons.link, color: Colors.red),
              title: Text(
                'Szent József Hackathon',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                launch_url('https://szentjozsef.jezsuita.hu/szent-jozsef-hackathon/');
              },
            ),
          ],
        ),
      ),
    );
  }


}
