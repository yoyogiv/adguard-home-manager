// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/logs/filter_status_modal.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/functions/format_time.dart';
import 'package:adguard_home_manager/providers/logs_provider.dart';

class LogsFiltersModal extends StatelessWidget {
  const LogsFiltersModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logsProvider = Provider.of<LogsProvider>(context);

    return LogsFiltersModalWidget(
      logsProvider: logsProvider
    );
  }
}

class LogsFiltersModalWidget extends StatefulWidget {
  final LogsProvider logsProvider;

  const LogsFiltersModalWidget({
    Key? key,
    required this.logsProvider
  }) : super(key: key);

  @override
  State<LogsFiltersModalWidget> createState() => _LogsFiltersModalWidgetState();
}

class _LogsFiltersModalWidgetState extends State<LogsFiltersModalWidget> {
  TextEditingController addressController = TextEditingController();
  String? addressFieldError;

  @override
  void initState() {
    addressController.text = widget.logsProvider.searchIpDomain ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final logsProvider = Provider.of<LogsProvider>(context);
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    final Map<String, String> translatedString = {
      "all": AppLocalizations.of(context)!.all, 
      "filtered": AppLocalizations.of(context)!.filtered, 
      "processed": AppLocalizations.of(context)!.processed, 
      "whitelisted": AppLocalizations.of(context)!.processedWhitelist, 
      "blocked": AppLocalizations.of(context)!.blocked, 
      "blocked_safebrowsing": AppLocalizations.of(context)!.blockedSafeBrowsing, 
      "blocked_parental": AppLocalizations.of(context)!.blockedParental, 
      "safe_search": AppLocalizations.of(context)!.safeSearch, 
    };

    void selectTime() async {
      DateTime now = DateTime.now();
      DateTime? dateValue = await showDatePicker(
        context: context, 
        initialDate: now, 
        firstDate: DateTime(now.year, now.month-1, now.day), 
        lastDate: now
      );
      if (dateValue != null) {
        TimeOfDay? timeValue = await showTimePicker(
          context: context, 
          initialTime: TimeOfDay.now(),
          helpText: AppLocalizations.of(context)!.selectTime,
        );
        if (timeValue != null) {
          DateTime value = DateTime(
            dateValue.year,
            dateValue.month,
            dateValue.day,
            timeValue.hour,
            timeValue.minute,
            dateValue.second
          ).toUtc();

          logsProvider.setLogsOlderThan(value);
        }
      }
    }

    void resetFilters() async {
      setState(() {
        addressController.text = '';
        addressFieldError = null;
      });

      logsProvider.setLoadStatus(0);

      logsProvider.resetFilters();

      final result = await getLogs(
        server: serversProvider.selectedServer!, 
        count: logsProvider.logsQuantity
      );

      if (result['result'] == 'success') {
        logsProvider.setLogsData(result['data']);
        logsProvider.setLoadStatus(1);
      }
      else {
        appConfigProvider.addLog(result['log']);
        logsProvider.setLoadStatus(2);
      }
    }

    void openSelectFilterStatus() {
      showModalBottomSheet(
        context: context, 
        builder: (context) => FilterStatusModal(
          value: logsProvider.selectedResultStatus,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent
      );
    }

    void validateAddress(String? value) {
      if (value != null && value != '') {
        RegExp ipAddress = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)(\.(?!$)|$)){4}$');
        RegExp domain = RegExp(r'^((?!-))(xn--)?[a-z0-9][a-z0-9-_]{0,61}[a-z0-9]{0,1}\.(xn--)?([a-z0-9\-]{1,61}|[a-z0-9-]{1,30}\.[a-z]{2,})$');
        if (ipAddress.hasMatch(value) == true || domain.hasMatch(value) == true) {
          setState(() {
            addressFieldError = null;
          });
          logsProvider.setSearchIpDomain(addressController.text);
        }
        else {
          setState(() {
            addressFieldError = AppLocalizations.of(context)!.invalidIpDomain;
          });
        }
      }
      else {
        setState(() {
          addressFieldError = AppLocalizations.of(context)!.ipDomainNotEmpty;
        });
      }
    }

    void filterLogs() async {
      Navigator.pop(context);

      logsProvider.setLoadStatus(0);

      logsProvider.setOffset(0);

      final result = await getLogs(
        server: serversProvider.selectedServer!, 
        count: logsProvider.logsQuantity,
        olderThan: logsProvider.logsOlderThan,
        responseStatus: logsProvider.selectedResultStatus,
        search: logsProvider.searchIpDomain,
      );
      if (result['result'] == 'success') {
        logsProvider.setLogsData(result['data']);
        logsProvider.setLoadStatus(1);
      }
      else {
        appConfigProvider.addLog(result['log']);
        logsProvider.setLoadStatus(2);
      }
    }

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: 470,
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28)
          )
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(
                top: 24,
                bottom: 20,
              ),
              child: Icon(
                Icons.filter_list_rounded,
                size: 26,
              ),
            ),
            Text(
              AppLocalizations.of(context)!.filters,
              style: const TextStyle(
                fontSize: 24
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 108,
                          child: TextFormField(
                            controller: addressController,
                            onChanged: validateAddress,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.link_rounded),
                              errorText: addressFieldError,
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10)
                                )
                              ),
                              labelText: AppLocalizations.of(context)!.ipDomain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              addressController.text = '';
                              addressFieldError = null;
                            });
                            logsProvider.setSearchIpDomain(null);
                          },
                          icon: const Icon(Icons.clear)
                        )
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: selectTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 24,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.logsOlderThan,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  logsProvider.logsOlderThan != null
                                    ? formatTimestampUTC(logsProvider.logsOlderThan!, 'HH:mm - dd/MM/yyyy')
                                    : AppLocalizations.of(context)!.notSelected,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: openSelectFilterStatus,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              size: 24,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.responseStatus,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${translatedString[logsProvider.selectedResultStatus]}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: resetFilters, 
                    child: Text(AppLocalizations.of(context)!.resetFilters)
                  ),
                  TextButton(
                    onPressed: filterLogs, 
                    child: Text(AppLocalizations.of(context)!.apply)
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}