import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shein_kosova/provider/search_provider.dart';
import 'package:shein_kosova/utils/AppColors.dart';

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
    borderRadius: BorderRadius.circular(22),
    child: Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.black54, size: 20),
          SizedBox(width: 8),
          Text(
            'Search',
            style: TextStyle(color: Colors.black45, fontSize: 14),
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
          context.pop();
        },
        child: const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.arrow_back_ios_new_outlined, size: 20),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    Provider.of<SearchProvider>(context, listen: false)
                        .search(query: value);
                  },
                  onFieldSubmitted: (value) {
                    Provider.of<SearchProvider>(context, listen: false)
                        .search(query: value);
                  },
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    Provider.of<SearchProvider>(context, listen: false).search(query: '');
                  },
                  child: const Icon(Icons.close, color: Colors.black45, size: 18),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
