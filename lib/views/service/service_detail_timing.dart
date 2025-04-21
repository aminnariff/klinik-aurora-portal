import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/models/service_branch/update_service_branch_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class TimeListManager extends StatefulWidget {
  final service_branch_model.Data? serviceBranch;

  const TimeListManager({super.key, required this.serviceBranch});

  @override
  State<TimeListManager> createState() => _TimeListManagerState();
}

class _TimeListManagerState extends State<TimeListManager> {
  late List<String> timeList;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    timeList = List<String>.from(widget.serviceBranch?.serviceBranchAvailableTime ?? []);
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _addTimeToList() {
    if (selectedTime != null) {
      setState(() {
        timeList.add(selectedTime!.format(context));
        selectedTime = null;
      });
    }
  }

  void _removeTimeFromList(int index) {
    setState(() {
      timeList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CardContainer(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          InputField(
                            field: InputFieldAttribute(
                              controller: TextEditingController(
                                text: selectedTime?.format(context),
                              ),
                              isEditable: false,
                              labelText: 'Selected Time',
                              suffixWidget: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: _pickTime,
                                    icon: const Icon(
                                      Icons.add,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            width: 300,
                          ),
                          // Text("Selected Time: ${selectedTime?.format(context) ?? ''}"),
                          // AppPadding.horizontal(),
                          // ElevatedButton(
                          //   onPressed: _pickTime,
                          //   child: const Text("Pick Time"),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Button(
                        _addTimeToList,
                        actionText: 'Add Time',
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.all(5),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        children: [
                          for (int index = 0; index < timeList.length; index++)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade300,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    timeList[index],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.black),
                                    onPressed: () => _removeTimeFromList(index),
                                  )
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (timeList.isEmpty)
                        const Text(
                          'No slots available.',
                        ),
                      AppPadding.vertical(),
                      Button(
                        () {
                          ServiceBranchController.update(
                              context,
                              UpdateServiceBranchRequest(
                                serviceBranchId: widget.serviceBranch?.serviceBranchId,
                                serviceBranchStatus: widget.serviceBranch?.serviceBranchStatus,
                                serviceBranchAvailableTime: timeList,
                              )).then((value) {
                            if (responseCode(value.code)) {
                              context.pop();
                              getLatestData();
                            } else {
                              showDialogError(
                                  context, value.data?.message ?? value.message ?? 'error'.tr(gender: 'generic'));
                            }
                          });
                        },
                        actionText: 'Update',
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getLatestData() {
    showLoading();
    ServiceBranchController.getAll(context, 1, 100, serviceId: widget.serviceBranch?.serviceId, serviceBranchStatus: 1)
        .then((value) {
      dismissLoading();
      context.read<ServiceBranchController>().serviceBranchResponse = value.data;
      showDialogSuccess(context, 'Timing for ${widget.serviceBranch?.branchName} has been successfully updated.');
    });
  }
}
