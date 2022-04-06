import 'dart:io';

import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import 'package:sodoit_todo/app/data/models/note.dart';
import 'package:sodoit_todo/app/data/services/local_services/boxes.dart';
import 'package:sodoit_todo/app/ui/pages/home/navigation_bar_views/notes_view_widgets/custom_icon_button.dart';
import 'package:sodoit_todo/app/ui/pages/home/navigation_bar_views/widgets/custom_badge.dart';
import 'package:sodoit_todo/app/ui/pages/note_detail/note_detail_controller.dart';
import 'package:sodoit_todo/app/ui/pages/note_detail/widgets/custom_expansion_container.dart';
import 'package:sodoit_todo/app/ui/pages/note_detail/widgets/custom_expansion_tile.dart';
import 'package:sodoit_todo/app/ui/pages/note_detail/widgets/note_detail_appbar_detail.dart';
import 'package:sodoit_todo/app/ui/pages/note_detail/widgets/popup_menu_item_widget.dart';
import 'package:sodoit_todo/app/ui/pages/note_edit_add/customizable_text/widgets/markdown_body_widget.dart';
import 'package:sodoit_todo/app/ui/utils/functions.dart';
import 'package:sodoit_todo/app/ui/utils/utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sodoit_todo/app/ui/widgets/custom_padding.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../constants/colors.dart';

class NoteDetailView extends GetView<NoteDetailController> {
  const NoteDetailView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Note>>(
      valueListenable: Boxes.getNotes().listenable(),
      builder: (BuildContext context, Box box, Widget? child) {
        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _customSliverAppBar(context),
              _body(context),
            ],
          ),
        );
      },
    );
  }

  SliverList _body(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          _buildNoteHeader(context),
          Utils.sizedBoxHeight3,
          _buildCategoryTitle(),
          Utils.sizedBoxHeight14,
          _buildContentContainer(context),
          controller.note.customizableText != null
              ? Visibility(
                  visible: controller.note.customizableText!.isNotEmpty
                      ? true
                      : false,
                  child: CustomPadding(
                    top: 7,
                    child: CustomExpansionTile(
                      title: "Customized Text".tr,
                      icon: const Icon(Icons.title),
                      content: [
                        Container(
                          alignment: Alignment.topLeft,
                          child: MarkdownBodyWidget(
                            data: controller.note.customizableText!,
                            isDataShowing: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(),
          _buildCheckboxContainer(),
          CustomExpansionContainer(
            items: controller.note.noteImages,
            icon: Icons.camera_alt,
            title: "noteDetail_CapturedPhotos",
            isImage: true,
            type: DocumentType.capturedPhotos,
          ),
          CustomExpansionContainer(
            items: controller.note.attachedDocuments,
            title: "noteDetail_SelectedDocuments",
            isImage: false,
            icon: Icons.attach_file,
            type: DocumentType.documents,
          ),
          CustomExpansionContainer(
            items: controller.note.customDrawings,
            title: "noteDetail_CustomDrawing",
            isImage: true,
            icon: Icons.brush,
            type: DocumentType.paints,
          ),
          _buildRecordedSoundsContainer(context),
        ],
      ),
    );
  }

  SliverAppBar _customSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight:
          controller.note.noteAvatar != null && controller.note.noteAvatar != ""
              ? Get.size.height / 3.5
              : 0,
      pinned: true,
      forceElevated: false,
      elevation: 3,
      primary: true,
      toolbarHeight: 0,
      leadingWidth: 30,
      flexibleSpace:
          controller.note.noteAvatar != null && controller.note.noteAvatar != ""
              ? GestureDetector(
                  onTap: () {
                    Get.to(() => NoteDetailAppbarDetail(note: controller.note));
                  },
                  child: FlexibleSpaceBar(
                    background: Image.file(
                      File(controller.note.noteAvatar!),
                      fit: BoxFit.cover,
                      width: double.maxFinite,
                    ),
                  ),
                )
              : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GestureDetector(
          onTap: () {
            Get.to(() => NoteDetailAppbarDetail(note: controller.note));
          },
          child: PhysicalModel(
            color: Get.isDarkMode ? AppColors.black : AppColors.white,
            elevation: 2,
            child: Container(
              height: kToolbarHeight,
              decoration: BoxDecoration(
                color: Get.isDarkMode ? AppColors.black : AppColors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () {
                      Get.back();
                    },
                  ),
                  Utils.sizedBoxWidth5,
                  Text(
                    "noteDetail_AppBarTitle".tr,
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                  const Spacer(),
                  Obx(
                    () => CustomIconButton(
                      onPressed: () {
                        var checkboxes = "";
                        if (controller.note.checkboxes != null &&
                            controller.note.checkboxes!.isNotEmpty) {
                          for (var checkbox
                              in controller.note.checkboxes!.keys) {
                            checkboxes += '$checkbox.\n';
                          }
                        }
                        controller.isPlaying.value
                            ? controller.stop()
                            : controller.speak(
                                controller.note.title,
                                controller.note.description! + checkboxes,
                              );
                      },
                      icon: controller.isPlaying.value
                          ? Icons.stop
                          : Icons.headphones,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: controller.choiceAction,
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) {
                      if (Get.locale != null &&
                          Get.locale!.languageCode == "en") {
                        return PopupMenuItemWidget.choices.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      } else {
                        return PopupMenuItemWidget.choicesTR
                            .map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice),
                          );
                        }).toList();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: Container(),
      stretch: true,
    );
  }

  IntrinsicHeight _buildNoteHeader(context) {
    return IntrinsicHeight(
      child: CustomPadding(
        left: 14.w,
        right: 14.w,
        top: 14.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SizedBox(
                width: Functions.generateStar(controller.note.notePriority) != 0
                    ? 260.w
                    : (Get.width - 60).w,
                child: _buildNoteTitle(controller.note),
              ),
            ),
            Visibility(
              visible: Functions.generateStar(controller.note.notePriority) != 0
                  ? true
                  : false,
              child: VerticalDivider(
                thickness: 1,
                width: 28.w,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            _buildPriorityStars(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxContainer() {
    if (controller.note.checkboxes != null &&
        controller.note.checkboxes!.isNotEmpty) {
      return Visibility(
        visible: controller.note.checkboxes!.isNotEmpty ? true : false,
        child: GetBuilder<NoteDetailController>(
          id: "checkbox_value",
          builder: (ctrl) {
            return CustomPadding(
              top: 7.h,
              child: CustomExpansionTile(
                initiallyExpanded: false,
                isNoteDetail: true,
                icon: const Icon(Icons.check_circle),
                title:
                    ctrl.getCheckboxContainerTitle(controller.note.checkboxes!),
                content: [
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: controller.note.checkboxes!.length,
                    itemBuilder: (context, index) {
                      return CheckboxListTile(
                        key: Key(index.toString()),
                        value:
                            controller.note.checkboxes!.values.elementAt(index),
                        onChanged: (value) {
                          ctrl.changeCheckboxStatus(
                              controller.note, index, value);
                        },
                        // activeColor: Colors.grey[700],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        dense: true,
                        title: Text(
                          "${index + 1}) " +
                              controller.note.checkboxes!.entries
                                  .elementAt(index)
                                  .key,
                          style: controller.getCheckboxTextStyle(controller
                              .note.checkboxes!.entries
                              .elementAt(index)
                              .value),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildRecordedSoundsContainer(BuildContext context) {
    if (controller.note.voiceRecord != null &&
        controller.note.voiceRecord!.isNotEmpty) {
      return CustomPadding(
        top: 7,
        child: CustomExpansionTile(
          isNoteDetail: true,
          title: "noteDetail_VoiceRecords".tr,
          icon: CustomBadge(
            icon: Icons.mic,
            documents: controller.note.voiceRecord!,
          ),
          initiallyExpanded: false,
          content: [
            ListView.builder(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                itemCount: controller.note.voiceRecord!.length,
                itemBuilder: (BuildContext context, int index) {
                  String fileName =
                      controller.note.voiceRecord![index].fileName;
                  String fileExtension =
                      controller.note.voiceRecord![index].fileExtension;

                  return Card(
                    child: ListTile(
                      title: Text(
                        fileName + "." + fileExtension,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      onTap: () {
                        OpenFile.open(controller.note.voiceRecord![index]);
                      },
                    ),
                  );
                }),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Text _buildNoteTitle(Note willShowNote) {
    return Text(
      willShowNote.title,
      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
      textAlign: TextAlign.start,
      //overflow: TextOverflow.ellipsis,
    );
  }

  Row _buildPriorityStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        for (int i = 0;
            i < Functions.generateStar(controller.note.notePriority);
            i++)
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w),
              child: const Icon(
                Icons.star,
                size: 16,
              )),
      ],
    );
  }

  Widget _buildCategoryTitle() {
    if (controller.note.noteCategory != null) {
      return CustomPadding(
        left: 14.w,
        right: 14.w,
        child: Text(
          controller.note.noteCategory!.title,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w500),
          textAlign: TextAlign.start,
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildContentContainer(context) {
    return Visibility(
      visible: controller.note.description!.isNotEmpty,
      child: Container(
        padding: const EdgeInsets.all(14),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
        ),
        child: SelectableLinkify(
          options: const LinkifyOptions(
            defaultToHttps: true,
            humanize: true,
            removeWww: true,
          ),
          toolbarOptions: const ToolbarOptions(
            copy: true,
            cut: true,
            paste: true,
            selectAll: true,
          ),
          onOpen: (link) => controller.openURL(link),
          text: controller.note.description!,
          linkStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
