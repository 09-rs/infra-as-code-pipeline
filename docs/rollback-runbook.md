\# Production Rollback Runbook



\## Purpose



This runbook defines the recovery procedure for a failed ECS production deployment.



The platform uses two rollback protections:



1\. ECS Deployment Circuit Breaker with rollback enabled.

2\. GitHub Actions automatic rollback to the previous ECS task definition.



The objective is to restore the last known healthy application version without manual server access.



\---



\## Deployment Flow



```text

Developer

&#x20;   |

&#x20;   v

GitHub Pull Request

&#x20;   |

&#x20;   v

Terraform Validation + TFLint

&#x20;   |

&#x20;   v

Docker Build

&#x20;   |

&#x20;   v

Amazon ECR

&#x20;   |

&#x20;   v

ECS Task Definition

&#x20;   |

&#x20;   v

ECS Deployment

&#x20;   |

&#x20;   v

Health Checks

&#x20;   |

&#x20;   +-------------------+

&#x20;   |                   |

&#x20; Healthy             Failed

&#x20;   |                   |

&#x20;   v                   v

&#x20;Deployment       ECS Circuit Breaker

&#x20; Successful          / GitHub Actions

&#x20;                        |

&#x20;                        v

&#x20;                Previous Task Definition

&#x20;                        |

&#x20;                        v

&#x20;                     Rollback

&#x20;                        |

&#x20;                        v

&#x20;                 Service Stabilized

