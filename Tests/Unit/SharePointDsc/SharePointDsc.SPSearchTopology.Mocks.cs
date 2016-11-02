namespace Microsoft.Office.Server.Search.Administration.Topology 
{ 
    public class AdminComponent 
    { 
        public string ServerName { get; set; } 
        public System.Guid ComponentId { get; set; } 
        public System.Guid ServerId { get; set; }
    }

    public class CrawlComponent 
    { 
        public string ServerName { get; set; } 
        public System.Guid ComponentId { get; set; } 
        public System.Guid ServerId {get; set;}
    }

    public class ContentProcessingComponent 
    { 
        public string ServerName { get; set; } 
        public System.Guid ComponentId { get; set; } 
        public System.Guid ServerId {get; set;}
    }

    public class AnalyticsProcessingComponent 
    { 
        public string ServerName { get; set; } 
        public System.Guid ComponentId { get; set; } 
        public System.Guid ServerId {get; set;}
    }

    public class QueryProcessingComponent 
    { 
        public string ServerName { get; set; } 
        public System.Guid ComponentId { get; set; } 
        public System.Guid ServerId {get; set;}
    }

    public class IndexComponent 
    { 
        public string ServerName { get; set; } 
        public System.Guid ComponentId { get; set; } 
        public System.Int32 IndexPartitionOrdinal { get; set; } 
        public System.Guid ServerId { get; set; }
    }
}
