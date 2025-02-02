import 'dart:typed_data';

class ProductItemModel {
  String? sellerName;
  String? sellerMobileNumber;
  double? productPrice;
  String? productName;
  String? productDesc;
  String? imageFile;

  ProductItemModel(
      {this.sellerName,
      this.productName,
      this.productPrice,
      this.sellerMobileNumber,
      this.productDesc,
      this.imageFile});

  Map<String, dynamic> toJson(
      String sellerName,
      String sellerMobileNumber,
      double productPrice,
      String productName,
      String productDesc,
      String imageFile) {
    return {
      'Seller Name': sellerName,
      'Seller Mobile No': sellerMobileNumber,
      'Product Price': productPrice,
      'Product Name': productName,
      'Product Description': productDesc,
      'Product Image': imageFile
    };
  }

  ProductItemModel fromJson(Map<String, dynamic> json) {
    return ProductItemModel(
      sellerName: json['Seller Name'],
      sellerMobileNumber: json['Seller Mobile No'],
      productPrice: json['Product Price'],
      productName: json['Product Name'],
      productDesc: json['Product Description'],
      imageFile: json['Product Image'],
    );
  }
}
