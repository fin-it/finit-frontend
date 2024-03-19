import 'package:capstone_project/models/foundItem.dart';
import 'package:capstone_project/services/remote_service.dart';
import 'package:flutter/material.dart';
import 'package:capstone_project/components/search_bar.dart';
import 'package:capstone_project/components/widgets/compose.dart';
import 'package:capstone_project/components/widgets/extd_compose.dart';
import 'package:capstone_project/components/filter_categories.dart';

class LostItemList extends StatefulWidget {
  const LostItemList({super.key});

  @override
  State<LostItemList> createState() => _LostItemListState();
}

class _LostItemListState extends State<LostItemList> {
  List<Datum>? losts;
  var isLoaded = false;

  ScrollController _scrollController = new ScrollController();
  bool isExtend = false;

  @override
  void initState() {
    super.initState();

    //fetch data from API
    getData();

    _scrollController.addListener(() {
      if (_scrollController.offset > 5) {
        setState(() {
          isExtend = true;
        });
      } else {
        setState(() {
          isExtend = false;
        });
      }
    });
  }

  getData() async {
    var data = await RemoteService().getLostItems();
    if (mounted) {
      // Check if the widget is mounted before calling setState
      setState(() {
        isLoaded = true;
        losts = data;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 35,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Text(
              'LOST & FOUND',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'JosefinSans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
          controller: _scrollController,
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: 25,
                    top: 25,
                  ),
                  child: Text(
                    'Found Something?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'JosefinSans',
                    ),
                  ),
                ),
                SizedBox(
                  width: 12,
                ),
                //show search bar component
                SrcBar(),
              ],
            ),
            //underline
            Container(
              margin: const EdgeInsets.only(left: 25, top: 10, right: 25),
              height: 2,
              color: Colors.black,
            ),
            const SizedBox(
              height: 10,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    FilterCategories(),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Visibility(
                visible: isLoaded,
                replacement: const Center(
                  child: CircularProgressIndicator(),
                ),
                child: GridView.builder(
                  itemCount: losts?.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10),
                  itemBuilder: (context, index) {
                    final latitude = double.parse(
                        losts![index].latitude); // Convert latitude to double
                    final longitude = double.parse(
                        losts![index].longitude); // Convert longitude to double

                    return FutureBuilder<String>(
                      future:
                          RemoteService().getLocationName(latitude, longitude),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Show error message if an error occurs
                          return Text('Error: ${snapshot.error}');
                        } else {
                          // Display the item with its location name
                          final locationName = snapshot.data;
                          return InkWell(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              decoration: BoxDecoration(
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 10,
                                      color: Color(0x33000000),
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white),
                              child: Column(
                                children: [
                                  Image.network(
                                    losts![index].itemImage,
                                    width: 100,
                                    height: 100,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      } else {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      }
                                    },
                                    errorBuilder: (BuildContext context,
                                        Object exception,
                                        StackTrace? stackTrace) {
                                      return const Text('Failed to load image');
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    losts![index].itemName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_pin),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          locationName ?? 'Location not found',
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ]),
      floatingActionButton:
          isExtend ? buildCompose(context) : buildExtendedCompose(context),
    );
  }
}
