class Pin {
  final String value;
  final bool isDecoy;

  const Pin({
    required this.value,
    this.isDecoy = false,
  });

  Pin copyWith({
    String? value,
    bool? isDecoy,
  }) {
    return Pin(
      value: value ?? this.value,
      isDecoy: isDecoy ?? this.isDecoy,
    );
  }
}
