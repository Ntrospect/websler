import 'dart:convert';

/// Represents an AI Discoverability Audit result with 7 weighted criteria
class AIAuditResult {
  final String id;
  final String url;
  final String websiteName;
  final DateTime auditTimestamp;
  final double overallScore; // 0-100 weighted score
  final int llmConfidenceScore; // 0-100%
  final String primaryIdentity; // One-sentence summary
  final Map<String, AICriterionScore> scores; // 7 criteria
  final List<String> keyStrengths;
  final List<String> criticalBlockers;
  final List<AIRecommendation> recommendations;
  final ImplementationRoadmap? implementationRoadmap;
  final List<String> predictedPrompts;
  final LiveTestResults? liveTestResults;

  AIAuditResult({
    required this.id,
    required this.url,
    required this.websiteName,
    required this.auditTimestamp,
    required this.overallScore,
    required this.llmConfidenceScore,
    required this.primaryIdentity,
    required this.scores,
    required this.keyStrengths,
    required this.criticalBlockers,
    required this.recommendations,
    this.implementationRoadmap,
    required this.predictedPrompts,
    this.liveTestResults,
  });

  /// Get color indicator for overall score (0-100)
  /// Green: 70+, Orange: 50-70, Red: <50
  String getScoreColor() {
    if (overallScore >= 70) return 'green';
    if (overallScore >= 50) return 'orange';
    return 'red';
  }

  /// Get status text for overall score
  String getScoreStatus() {
    if (overallScore >= 80) return 'Excellent AI Visibility';
    if (overallScore >= 70) return 'Good AI Visibility';
    if (overallScore >= 50) return 'Moderate AI Visibility';
    if (overallScore >= 30) return 'Poor AI Visibility';
    return 'Critical - Not AI Discoverable';
  }

  /// Get confidence level text
  String getConfidenceLevel() {
    if (llmConfidenceScore >= 80) return 'High';
    if (llmConfidenceScore >= 60) return 'Moderate';
    if (llmConfidenceScore >= 40) return 'Low';
    return 'Very Low';
  }

  /// Parse from JSON response from backend
  factory AIAuditResult.fromJson(Map<String, dynamic> json) {
    // Parse scores
    final scoresMap = <String, AICriterionScore>{};
    if (json['scores'] != null) {
      (json['scores'] as Map<String, dynamic>).forEach((key, value) {
        scoresMap[key] = AICriterionScore.fromJson(key, value as Map<String, dynamic>);
      });
    }

    // Parse recommendations
    final recommendations = <AIRecommendation>[];
    if (json['recommendations'] != null) {
      for (final rec in json['recommendations'] as List) {
        recommendations.add(AIRecommendation.fromJson(rec as Map<String, dynamic>));
      }
    }

    // Parse roadmap
    ImplementationRoadmap? roadmap;
    if (json['implementation_roadmap'] != null) {
      roadmap = ImplementationRoadmap.fromJson(json['implementation_roadmap'] as Map<String, dynamic>);
    }

    // Parse live test results
    LiveTestResults? liveTests;
    if (json['live_test_results'] != null) {
      liveTests = LiveTestResults.fromJson(json['live_test_results'] as Map<String, dynamic>);
    }

    return AIAuditResult(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      websiteName: json['website_name'] as String? ?? '',
      auditTimestamp: json['audit_timestamp'] != null
          ? DateTime.parse(json['audit_timestamp'] as String)
          : DateTime.now(),
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      llmConfidenceScore: (json['llm_confidence_score'] as num?)?.toInt() ?? 0,
      primaryIdentity: json['primary_identity'] as String? ?? '',
      scores: scoresMap,
      keyStrengths: List<String>.from(json['key_strengths'] as List? ?? []),
      criticalBlockers: List<String>.from(json['critical_blockers'] as List? ?? []),
      recommendations: recommendations,
      implementationRoadmap: roadmap,
      predictedPrompts: List<String>.from(json['predicted_prompts'] as List? ?? []),
      liveTestResults: liveTests,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'website_name': websiteName,
      'audit_timestamp': auditTimestamp.toIso8601String(),
      'overall_score': overallScore,
      'llm_confidence_score': llmConfidenceScore,
      'primary_identity': primaryIdentity,
      'scores': scores.map((k, v) => MapEntry(k, v.toJson())),
      'key_strengths': keyStrengths,
      'critical_blockers': criticalBlockers,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'implementation_roadmap': implementationRoadmap?.toJson(),
      'predicted_prompts': predictedPrompts,
      'live_test_results': liveTestResults?.toJson(),
    };
  }

  /// Create from stored JSON string
  static AIAuditResult? fromJsonString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AIAuditResult.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON string for storage
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Get formatted date string
  String get formattedDate {
    return '${auditTimestamp.month}/${auditTimestamp.day}/${auditTimestamp.year}';
  }

  /// Get formatted time string
  String get formattedTime {
    final hour = auditTimestamp.hour.toString().padLeft(2, '0');
    final minute = auditTimestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Represents a score for a single AI discoverability criterion
class AICriterionScore {
  final String name;
  final double score; // 0-10
  final double weight; // 0.0-1.0
  final String observation;
  final List<String> findings;
  final List<String> recommendations;

  AICriterionScore({
    required this.name,
    required this.score,
    required this.weight,
    required this.observation,
    required this.findings,
    required this.recommendations,
  });

  /// Get color for score (0-10)
  String getScoreColor() {
    if (score >= 7) return 'green';
    if (score >= 5) return 'orange';
    return 'red';
  }

  /// Get status text
  String getScoreStatus() {
    if (score >= 8) return 'Excellent';
    if (score >= 7) return 'Good';
    if (score >= 5) return 'Moderate';
    if (score >= 3) return 'Needs Improvement';
    return 'Critical';
  }

  /// Get weighted contribution (0-100)
  double get weightedContribution => score * weight * 10;

  factory AICriterionScore.fromJson(String name, Map<String, dynamic> json) {
    return AICriterionScore(
      name: name,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      observation: json['observation'] as String? ?? '',
      findings: List<String>.from(json['findings'] as List? ?? []),
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'weight': weight,
      'observation': observation,
      'findings': findings,
      'recommendations': recommendations,
    };
  }
}

/// Represents an AI audit recommendation with ROI analysis
class AIRecommendation {
  final String title;
  final String criterion;
  final String description;
  final String costOfImplementation; // "Low", "Medium", "High"
  final String expectedImprovement;
  final String roiAssessment; // "High", "Medium", "Low"
  final String timeline;
  final int priority;

  AIRecommendation({
    required this.title,
    required this.criterion,
    required this.description,
    required this.costOfImplementation,
    required this.expectedImprovement,
    required this.roiAssessment,
    required this.timeline,
    required this.priority,
  });

  /// Get color for ROI level
  String getRoiColor() {
    switch (roiAssessment) {
      case 'High':
        return 'green';
      case 'Medium':
        return 'orange';
      case 'Low':
        return 'red';
      default:
        return 'grey';
    }
  }

  /// Get color for cost level
  String getCostColor() {
    switch (costOfImplementation) {
      case 'Low':
        return 'green';
      case 'Medium':
        return 'orange';
      case 'High':
        return 'red';
      default:
        return 'grey';
    }
  }

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      title: json['title'] as String? ?? '',
      criterion: json['criterion'] as String? ?? '',
      description: json['description'] as String? ?? '',
      costOfImplementation: json['cost_of_implementation'] as String? ?? 'Medium',
      expectedImprovement: json['expected_improvement'] as String? ?? '',
      roiAssessment: json['roi_assessment'] as String? ?? 'Medium',
      timeline: json['timeline'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'criterion': criterion,
      'description': description,
      'cost_of_implementation': costOfImplementation,
      'expected_improvement': expectedImprovement,
      'roi_assessment': roiAssessment,
      'timeline': timeline,
      'priority': priority,
    };
  }
}

/// Represents a phase in the implementation roadmap
class RoadmapPhase {
  final String name;
  final String timeframe;
  final List<String> tasks;
  final String expectedScoreImprovement;
  final String totalEffort;

  RoadmapPhase({
    required this.name,
    required this.timeframe,
    required this.tasks,
    required this.expectedScoreImprovement,
    required this.totalEffort,
  });

  factory RoadmapPhase.fromJson(Map<String, dynamic> json) {
    return RoadmapPhase(
      name: json['name'] as String? ?? '',
      timeframe: json['timeframe'] as String? ?? '',
      tasks: List<String>.from(json['tasks'] as List? ?? []),
      expectedScoreImprovement: json['expected_score_improvement'] as String? ?? '',
      totalEffort: json['total_effort'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timeframe': timeframe,
      'tasks': tasks,
      'expected_score_improvement': expectedScoreImprovement,
      'total_effort': totalEffort,
    };
  }
}

/// Represents the full implementation roadmap
class ImplementationRoadmap {
  final List<RoadmapPhase> phases;
  final String totalImprovement;

  ImplementationRoadmap({
    required this.phases,
    required this.totalImprovement,
  });

  factory ImplementationRoadmap.fromJson(Map<String, dynamic> json) {
    final phases = <RoadmapPhase>[];
    if (json['phases'] != null) {
      for (final phase in json['phases'] as List) {
        phases.add(RoadmapPhase.fromJson(phase as Map<String, dynamic>));
      }
    }
    return ImplementationRoadmap(
      phases: phases,
      totalImprovement: json['total_improvement'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phases': phases.map((p) => p.toJson()).toList(),
      'total_improvement': totalImprovement,
    };
  }
}

/// Represents a single live LLM test result
class LiveTestResult {
  final String llmName;
  final String query;
  final bool found;
  final String accuracy;
  final String snippet;

  LiveTestResult({
    required this.llmName,
    required this.query,
    required this.found,
    required this.accuracy,
    required this.snippet,
  });

  factory LiveTestResult.fromJson(Map<String, dynamic> json) {
    return LiveTestResult(
      llmName: json['llm_name'] as String? ?? '',
      query: json['query'] as String? ?? '',
      found: json['found'] as bool? ?? false,
      accuracy: json['accuracy'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'llm_name': llmName,
      'query': query,
      'found': found,
      'accuracy': accuracy,
      'snippet': snippet,
    };
  }
}

/// Represents all live test results
class LiveTestResults {
  final List<LiveTestResult> tests;
  final int overallVisibilityScore;

  LiveTestResults({
    required this.tests,
    required this.overallVisibilityScore,
  });

  factory LiveTestResults.fromJson(Map<String, dynamic> json) {
    final tests = <LiveTestResult>[];
    if (json['tests'] != null) {
      for (final test in json['tests'] as List) {
        tests.add(LiveTestResult.fromJson(test as Map<String, dynamic>));
      }
    }
    return LiveTestResults(
      tests: tests,
      overallVisibilityScore: (json['overall_visibility_score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tests': tests.map((t) => t.toJson()).toList(),
      'overall_visibility_score': overallVisibilityScore,
    };
  }
}
