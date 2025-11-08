import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

CarouselSlider buildCarouselSlider(List<Widget> imageSliders, BuildContext context, onTap) {
  return CarouselSlider(
    options: CarouselOptions(
      autoPlay: true,
      height: 400

    ),
    items: List.generate(
      imageSliders.length,
      (index) => Container(
        child: GestureDetector(
          onTap: () => onTap[index](),
          child: imageSliders[index],
        ),
      ),
    ),

  );
}