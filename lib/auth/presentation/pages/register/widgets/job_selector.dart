import 'package:flutter/material.dart';

class JobSelector extends StatelessWidget {
  final String? selectedJob;
  final List<String> jobs;
  final ValueChanged<String> onJobSelected;

  const JobSelector({
    super.key,
    required this.selectedJob,
    required this.jobs,
    required this.onJobSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Job',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              'Example:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...jobs.map((job) => _JobOption(
          job: job,
          isSelected: selectedJob == job,
          onTap: () => onJobSelected(job),
        )).toList(),
      ],
    );
  }
}

class _JobOption extends StatelessWidget {
  final String job;
  final bool isSelected;
  final VoidCallback onTap;

  const _JobOption({
    required this.job,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                job,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}