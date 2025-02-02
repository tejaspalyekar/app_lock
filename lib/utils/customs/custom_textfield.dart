// import 'package:ar_ecommerce_app/features/upload_new_item/view_model/upload_new_item_view_model.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:provider/provider.dart';

// class customTextField extends StatelessWidget {
//   customTextField(
//       {super.key,
//       required this.textController,
//       required this.textFieldName,
//       required this.isDigitKeyboard,
//       required this.isMobileNo});
//   String textFieldName;
//   bool isDigitKeyboard;
//   TextEditingController textController;
//   bool isMobileNo;
//   @override
//   Widget build(BuildContext context) {
//     return FormBuilderTextField(
//         maxLength: isMobileNo ? 10 : 50,
//         keyboardType:
//             isDigitKeyboard ? TextInputType.number : TextInputType.text,
//         decoration: InputDecoration(
//             counter: SizedBox(),
//             icon: isMobileNo
//                 ? Padding(
//                     padding: const EdgeInsets.only(left: 20),
//                     child: CountryCodePicker(
//                       onChanged: (value) =>
//                           Provider.of<UploadNewItemViewModel>(context)
//                               .countryCode = value.code!,
//                       backgroundColor: Colors.grey,
//                       flagWidth: 20,
//                       showFlag: false,

//                       initialSelection: 'IN',
//                       favorite: const ['+91', 'IN'],
//                       showOnlyCountryWhenClosed: false,
//                       textStyle: Theme.of(context).textTheme.titleSmall,
//                       // optional. aligns the flag and the Text left
//                       alignLeft: false,
//                     ),
//                   )
//                 : const SizedBox(),
//             hintText: 'Enter $textFieldName',
//             border: const OutlineInputBorder(
//                 borderRadius: BorderRadius.all(Radius.circular(20)))),
//         controller: textController,
//         name: textFieldName);
//   }
// }
