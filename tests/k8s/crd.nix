{ config, lib, kubenix, pkgs, k8sVersion, ... }:

with lib;

let
  crd = config.kubernetes.api.resources.customResourceDefinitions.crontabs;
  latestCrontab = config.kubernetes.api.resources.cronTabs.latest;
in {
  imports = with kubenix.modules; [ test k8s ];

  test = {
    name = "k8s-crd";
    description = "Simple test tesing CRD";
    enable = builtins.compareVersions config.kubernetes.version "1.8" >= 0;
    assertions = [{
      message = "CRD should have group and version set";
      assertion =
        crd.spec.group == "stable.example.com" &&
        crd.spec.version == "v1";
    } {
      message = "Custom resource should have correct version set";
      assertion = latestCrontab.apiVersion == "stable.example.com/v2";
    }];
    testScript = ''
      $kube->waitUntilSucceeds("kubectl apply -f ${config.kubernetes.result}");
      $kube->succeed("kubectl get crds | grep -i crontabs");
      $kube->succeed("kubectl get crontabs | grep -i versioned");
      $kube->succeed("kubectl get crontabs | grep -i latest");
    '';
  };

  kubernetes.version = k8sVersion;

  kubernetes.resources.customResourceDefinitions.crontabs = {
    metadata.name = "crontabs.stable.example.com";
    spec = {
      group = "stable.example.com";
      version = "v1";
      scope = "Namespaced";
      names = {
        plural = "crontabs";
        singular = "crontab";
        kind = "CronTab";
        shortNames = ["ct"];
      };
    };
  };

  kubernetes.resources.customResourceDefinitions.crontabsv2 = {
    metadata.name = "crontabs.stable.example.com";
    spec = {
      group = "stable.example.com";
      version = "v2";
      scope = "Namespaced";
      names = {
        plural = "crontabs";
        singular = "crontab";
        kind = "CronTab";
        shortNames = ["ct"];
      };
    };
  };

  kubernetes.createCustomTypesFromCRDs = true;

  kubernetes.customTypes = mkMerge [
    {
      "stable.example.com/v1/CronTab" = {
        attrName = "cronTabs";
        description = "CronTabs resources";
        module = {
          options.schedule = mkOption {
            description = "Crontab schedule script";
            type = types.str;
          };
        };
      };
    }
    {
      "stable.example.com/v2/CronTab" = {
        description = "CronTabs resources";
        attrName = "cronTabs";
        module = {
          options = {
            schedule = mkOption {
              description = "Crontab schedule script";
              type = types.str;
            };

            command = mkOption {
              description = "Command to run";
              type = types.str;
            };
          };
        };
      };
    }

    [{
      group = "stable.example.com";
      version = "v3";
      kind = "CronTab";
      description = "CronTabs resources";
      attrName = "cronTabsV3";
      module = {
        options = {
          schedule = mkOption {
            description = "Crontab schedule script";
            type = types.str;
          };

          command = mkOption {
            description = "Command to run";
            type = types.str;
          };
        };
      };
    }]
  ];

  kubernetes.resources."stable.example.com"."v1".CronTab.versioned.spec.schedule = "* * * * *";
  kubernetes.resources.cronTabs.latest.spec.schedule = "* * * * *";
  kubernetes.resources.cronTabsV3.latest.spec.schedule = "* * * * *";
}
