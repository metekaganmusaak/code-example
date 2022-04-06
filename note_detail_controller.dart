import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sodoit_todo/app/data/models/note.dart';
import 'package:sodoit_todo/app/ui/core/global_dialogs.dart';
import 'package:sodoit_todo/app/ui/pages/note_detail/widgets/popup_menu_item_widget.dart';
import 'package:sodoit_todo/app/ui/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/local_services/pdf_generator_api.dart';
import '../../widgets/toast_messages.dart';

class NoteDetailController extends GetxController {
  late Note note;
  late FlutterTts flutterTts;

  RxBool isPlaying = false.obs;

  RxBool isLongPressed = false.obs;

  void isLanguageEnglish() async {
    if (Get.locale!.languageCode == "en") {
      await flutterTts.setLanguage("en-US");
    } else if (Get.locale!.languageCode == "tr") {
      await flutterTts.setLanguage("tr-TR");
    }
  }

  void choiceAction(String choice) async {
    if (choice == PopupMenuItemWidget.delete ||
        choice == PopupMenuItemWidget.deleteTR) {
      await GlobalDialogs.noteDeleteDialog(note, true, Get.context);
    } else if (choice == PopupMenuItemWidget.edit ||
        choice == PopupMenuItemWidget.editTR) {
      Get.toNamed("/note_edit", arguments: note);
    } else if (choice == PopupMenuItemWidget.share ||
        choice == PopupMenuItemWidget.shareTR) {
      List<String> docs = [];
      String sharedContent = "";

      if (note.description != null && note.description!.isNotEmpty) {
        sharedContent = note.description ?? "";
      }

      if (note.noteImages != null) {
        for (var images in note.noteImages!) {
          docs.add(images);
        }
      }
      if (note.attachedDocuments != null) {
        for (var documents in note.attachedDocuments!) {
          docs.add(documents);
        }
      }
      if (note.customDrawings != null && note.customDrawings!.isNotEmpty) {
        for (var drawing in note.customDrawings!) {
          docs.add(drawing);
        }
      }
      if (note.voiceRecord != null && note.voiceRecord!.isNotEmpty) {
        for (var voice in note.voiceRecord!) {
          docs.add(voice);
        }
      }

      if (note.checkboxes != null && note.checkboxes!.isNotEmpty) {
        for (var item in note.checkboxes!.keys) {
          sharedContent += '\n\u2022 $item';
        }
      }

      if (docs.isEmpty) {
        if (note.description!.isEmpty && note.description == null) {
          await Share.share(note.title);
        } else {
          await Share.share(note.title + "\n\n" + sharedContent);
        }
      } else {
        if (note.description!.isEmpty && note.description == null) {
          await Share.shareFiles(docs, text: note.title, mimeTypes: docs);
        } else {
          await Share.shareFiles(docs,
              text: note.title + "\n\n" + sharedContent);
        }
      }
      docs.clear();
      sharedContent = "";
    } else if (choice == PopupMenuItemWidget.saveAsPDF ||
        choice == PopupMenuItemWidget.saveAsPDFTR) {
      String content = "";
      if (note.description != null && note.description!.isNotEmpty) {
        content = note.description ?? "";
      }

      List<String> checkboxes = [];
      if (note.checkboxes != null && note.checkboxes!.isNotEmpty) {
        for (var checkbox in note.checkboxes!.keys) {
          checkboxes.add(checkbox);
        }
      }

      List<String> images = [];
      if (note.noteImages != null && note.noteImages!.isNotEmpty) {
        for (var image in note.noteImages!) {
          images.add(image);
        }
      }

      if (note.attachedDocuments != null &&
          note.attachedDocuments!.isNotEmpty) {
        for (var doc in note.attachedDocuments!) {
          if (doc.isImageFileName || doc.fileExtension == "webp") {
            images.add(doc);
          }
        }
      }

      if (note.customDrawings != null && note.customDrawings!.isNotEmpty) {
        for (var drawing in note.customDrawings!) {
          images.add(drawing);
        }
      }

      if (await Permission.storage.request() == PermissionStatus.granted ||
          await Permission.accessMediaLocation.request() ==
              PermissionStatus.granted ||
          await Permission.manageExternalStorage.request() ==
              PermissionStatus.granted) {
        final savedPdfFile = await PdfGeneratorApi.generatePdf(
          note.title,
          content,
          checkboxes,
          images,
        );

        ToastMessages.showToast(
            "PDF File Generated and saved to ${savedPdfFile.path}.${'\n'}Generated PDF Opening");

        Future.delayed(const Duration(seconds: 2)).then((_) {
          PdfGeneratorApi.openFile(savedPdfFile);
        });
      } else {
        await Permission.storage.request();
        await Permission.accessMediaLocation.request();
        await Permission.manageExternalStorage.request();
        ToastMessages.showToast("İzinlerde hata ile karşılaşıldı".tr);
      }
    } 
    // else if (choice == PopupMenuItemWidget.shortcut ||
    //     choice == PopupMenuItemWidget.shortcutTR) {
    //       const QuickActions quickActions = QuickActions();
    //       quickActions.setShortcutItems([
    //         ShortcutItem(type: note.noteCreatedTime.toString(), localizedTitle: note.title, icon: note.noteAvatar)
    //       ]);
    //       quickActions.initialize((type) { 
    //         if(type == note.noteCreatedTime.toString())
    //         {
    //           Get.to(()=> const NoteDetailView(), arguments: note);
    //         }
    //       });
    //     }
  }

  ttsInitilization() async {
    isLanguageEnglish();

    flutterTts.setStartHandler(() {
      isPlaying.value = true;
    });

    flutterTts.setCompletionHandler(() {
      isPlaying.value = false;
    });

    flutterTts.setErrorHandler((message) {
      isPlaying.value = false;
    });
  }

  speak(String title, String? content) async {
    if (content != null && content.isNotEmpty) {
      var result = await flutterTts.speak("$title. $content");
      if (result == 1) {
        isPlaying.value = true;
      }
    } else {
      var result = await flutterTts.speak("$title.");
      if (result == 1) {
        isPlaying.value = true;
      }
    }
  }

  stop() async {
    var result = await flutterTts.stop();
    if (result == 1) {
      isPlaying.value = false;
    }
  }

  @override
  void onClose() {
    flutterTts.stop();
    super.onClose();
  }

  @override
  onInit() {
    note = Get.arguments;

    flutterTts = FlutterTts();
    ttsInitilization();

    super.onInit();
  }

  RxString directoryPath = "".obs;

  var isHideButtonTapped = false.obs;

  var isExpansionTileExpanded = false.obs;

  changeCheckboxStatus(Note note, int index, bool? value) {
    note.checkboxes!.addIf(
      true,
      note.checkboxes!.keys.elementAt(index),
      value!,
    );
    note.save();
    update(['checkbox_value']);
  }

  changeCheckboxStatus2(Note note, int index) {
    note.checkboxes!.addIf(
      true,
      note.checkboxes!.keys.elementAt(index),
      !note.checkboxes!.values.elementAt(index),
    );
    update(['checkbox_value']);
  }

  TextStyle? getCheckboxTextStyle(bool? currentCheckbox) {
    if (currentCheckbox != null) {
      if (currentCheckbox == true) {
        return TextStyle(
          fontSize: 16,
          decoration: TextDecoration.lineThrough,
          decorationThickness: 3,
          decorationColor: Theme.of(Get.context!).toggleableActiveColor,
        );
      } else {
        return const TextStyle(
          fontSize: 16,
        );
      }
    }
    return null;
  }

  String getCheckboxContainerTitle(Map<String, bool>? checkboxes) {
    int checkboxesLength = 0;
    int doneCheckboxesLength = 0;
    if (checkboxes != null) {
      checkboxesLength = checkboxes.length;

      for (var checkbox in checkboxes.entries) {
        if (checkbox.value == true) {
          doneCheckboxesLength += 1;
        } else {}
      }
    }

    return "checkboxContainerTitle".tr +
        "\t\t$doneCheckboxesLength/$checkboxesLength";
  }

  RxList<String> listOfDesc = RxList<String>.empty(growable: true);
  RxList<String> getPhoneNums = RxList<String>.empty(growable: true);

  contentHasPhoneNumber(String? description) {
    if (description != null) {
      listOfDesc.value = description.split(" ");

      for (var desc in listOfDesc) {
        if (desc.isPhoneNumber) {
          getPhoneNums.add(desc);
        }
      }
    }
  }

  phoneCall(List<String> phoneNumbers, int index) async {
    if (await canLaunch(phoneNumbers[index])) {
      await launch('tel:${phoneNumbers[index]}');
    }
  }

  openURL(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(
        link.url,
        forceSafariVC: false,
        forceWebView: false,
        enableJavaScript: true,
      );
    } else {
      throw "Could not launch URL: $link";
    }
  }
}
