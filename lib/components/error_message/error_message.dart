part of premo_table;

/// Standardised widget to display errors to the user in a consistent format
class ErrorMessage extends StatelessWidget {
  final String error;
  final String? footerText;
  final Function? footerTextOnTap;

  ErrorMessage({
    required this.error,
    this.footerText,
    this.footerTextOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Center(
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
              SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  text: '$error',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ),
              footerText != null ? SizedBox(height: 10) : Container(),
              footerText != null
                  ? RichText(
                      text: TextSpan(
                        text: footerText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (footerTextOnTap != null) {
                              footerTextOnTap!();
                            }
                          },
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
