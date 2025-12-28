import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import '../utils/AppColors.dart';

Widget buildSearchBar(BuildContext context) {
  return InkWell(
    onTap: () {
      context.push('/search');
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.04,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Search products...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          Icon(Icons.search, color: Colors.grey, size: 16),
        ],
      ),
    ),
  );
}

Widget buildProductSearchBar(BuildContext context, String searchTitle) {
  return InkWell(
    onTap: () {
      context.push('/search');
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.04,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.black),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
              child: Text(
                searchTitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.005),
            width: MediaQuery.of(context).size.width * 0.12,
            height: MediaQuery.of(context).size.height * 0.035,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildSquareSearchBar(BuildContext context) {
  return InkWell(
    onTap: () {
      context.push('/search');
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: MediaQuery.of(context).size.height * 0.04,
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
              child: const Text(
                'Search',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.005),
            width: MediaQuery.of(context).size.width * 0.12,
            height: MediaQuery.of(context).size.height * 0.035,
            decoration: BoxDecoration(
              color: AppColors.black,
            ),
            child: const Icon(
              Icons.search,
              color: Colors.grey,
              size: 20,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget searchbarTextField(BuildContext context, TextEditingController controller) {
  return Row(
    children: [
      InkWell(

        onTap: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back_ios_new_outlined),
      ),
      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
      Expanded(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.04,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.black),
          ),
          child: Row(
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (value) {
                      Provider.of<SearchProvider>(context, listen: false)
                          .search(query: value);
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Provider.of<SearchProvider>(context, listen: false)
                      .search(query: controller.text);
                },
                child: Container(
                  margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.005),
                  width: MediaQuery.of(context).size.width * 0.12,
                  height: MediaQuery.of(context).size.height * 0.035,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.search,
                    color: AppColors.iconWhite,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
