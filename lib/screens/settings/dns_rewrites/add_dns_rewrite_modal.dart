import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/models/rewrite_rules.dart';

class AddDnsRewriteModal extends StatefulWidget {
  final void Function(RewriteRulesData) onConfirm;

  const AddDnsRewriteModal({
    Key? key,
    required this.onConfirm
  }) : super(key: key);

  @override
  State<AddDnsRewriteModal> createState() => _AddDnsRewriteModalState();
}

class _AddDnsRewriteModalState extends State<AddDnsRewriteModal> {
  final TextEditingController domainController = TextEditingController();
  String? domainError;
  final TextEditingController answerController = TextEditingController();

  bool validData = false;

  void validateDomain(String value) {
    final domainRegex = RegExp(r'^([a-z0-9|-]+\.)*[a-z0-9|-]+\.[a-z]+$');
    if (domainRegex.hasMatch(value)) {
      setState(() => domainError = null);
    }
    else {
      setState(() => domainError = AppLocalizations.of(context)!.domainNotValid);
    }
    checkValidValues();
  }

  void checkValidValues() {
    if (
      domainController.text != '' &&
      domainError == null &&
      answerController.text != ''
    ) {
      setState(() => validData = true);
    }
    else {
      setState(() => validData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        height: 410,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28)
          ),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Icon(
                Icons.add,
                size: 26,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.addDnsRewrite,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TextFormField(
                controller: domainController,
                onChanged: validateDomain,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10)
                    )
                  ),
                  errorText: domainError,
                  labelText: AppLocalizations.of(context)!.domain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: TextFormField(
                controller: answerController,
                onChanged: (_) => checkValidValues(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.system_update_alt_rounded),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10)
                    )
                  ),
                  labelText: AppLocalizations.of(context)!.answer,
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 20,
                      right: 28
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        const SizedBox(width: 20),
                        TextButton(
                          onPressed: validData == true
                            ? () {
                              Navigator.pop(context);
                              widget.onConfirm(
                                RewriteRulesData(
                                  domain: domainController.text, 
                                  answer: answerController.text
                                )
                              );
                            }
                            : null,
                          child: Text(
                            AppLocalizations.of(context)!.confirm,
                            style: TextStyle(
                              color: validData == true
                                ? Theme.of(context).primaryColor
                                : Colors.grey
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}