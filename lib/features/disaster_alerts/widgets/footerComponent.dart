import 'package:flutter/material.dart';

class FooterComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Image.network('https://dashboard.codeparrot.ai/api/image/Z6n1ufrycnbNR_lw/home-24.png', height: 40),
          Image.network('https://dashboard.codeparrot.ai/api/image/Z6n1ufrycnbNR_lw/powerbut.png', height: 40),
          Image.network('https://dashboard.codeparrot.ai/api/image/Z6n1ufrycnbNR_lw/bulb.png', height: 40),
        ],
      ),
    );
  }
}
